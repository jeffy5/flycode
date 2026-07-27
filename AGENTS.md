# AGENTS.md - flycode Agent Guide
本文件给在本仓库工作的 agent 使用，目标是最小改动、风格一致、可测试、可维护。

## 1) 项目概览
- Flutter + Dart (`sdk: ^3.11.0`)
- 状态管理：Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- 路由：`go_router`
- 本地存储：`shared_preferences`, `sqflite`
- 网络与模型：`http`, `json_serializable`
- 代码生成：`build_runner`, `riverpod_generator`
- 主题系统：`ThemeData` + `ThemeExtension(AppThemeTokens)`

关键目录：
```text
lib/
  app.dart
  router.dart
  theme/
  pages/
  widgets/
  providers/
  service/api/
  models/
  database/
test/
```

## 2) Build / Lint / Test 命令
常用命令：
```bash
flutter pub get
flutter run
flutter analyze
dart format .
```

测试命令（含单测）：
```bash
flutter test
flutter test test/path/to/xxx_test.dart
flutter test --name="test case name"
flutter test test/path/to/xxx_test.dart --name="test case name"
```

常见示例：
```bash
flutter test test/session_status_provider_test.dart
flutter test test/session_status_provider_test.dart --name="returns loading state"
```

代码生成（修改 provider/model 后必须执行）：
```bash
dart run build_runner build --delete-conflicting-outputs
```

建议提交前检查：
```bash
dart format .
flutter analyze
flutter test
```

## 3) 代码风格规范
### 3.1 命名
- 文件/目录：`snake_case`
- 类/枚举：`PascalCase`
- 变量/函数/方法：`camelCase`
- 测试：`*_test.dart`
- 生成文件：`*.g.dart`（禁止手改）

### 3.2 Imports
- 第三方包使用 `package:`
- 仓库内部按现有风格优先相对导入
- 使用生成代码时必须有 `part 'xxx.g.dart';`
- 保持 import 简洁，不引入未使用项

### 3.3 格式化与类型
- 强制 `dart format .`
- 多行参数保留 trailing comma
- 公共函数与复杂函数显式返回类型
- 默认 `final`，仅在需要重赋值时用 `var`
- 字符串优先单引号
- 能 `const` 就 `const`

### 3.4 Riverpod
- 新 provider 优先 `@riverpod` + 生成代码
- 读状态用 `ref.watch(...)`
- 动作用 `ref.read(provider.notifier)`
- 异步状态使用 `AsyncValue`
- provider 保持单一职责

### 3.5 错误处理
- 网络层按类型处理异常（`ApiException`, `SocketException` 等）
- UI 层展示可读错误文案，不泄露底层细节
- 不要无声吞异常；降级处理要可观察

### 3.6 模型与序列化
- API 模型在 `lib/service/api/models/`
- 优先 `json_serializable`
- 本地简单模型可手写 `fromJson/toJson`
- 不可变对象优先提供 `copyWith`

## 4) 页面设计（设计阶段）
这一部分回答：如何设计页面。

设计原则：
- 信息层级优先，视觉装饰次之
- 组件优先复用，避免一次性样式
- 统一 token（颜色/字号/圆角/间距）
- 同时考虑 Light / Dark
- 设计时必须优先使用变量（design tokens），不要直接写散落的硬编码值，确保全局视觉统一

当前项目视觉基线（建议）：
- 字体：Inter（正文）+ PlusJakartaSans（标题）
- 主色：`#8B5CF6`（primary）
- 圆角：14 / 24 / pill（见 `AppThemeTokens`）
- 页面状态完整：loading / empty / error / disabled

设计自检：
- 是否一眼看懂层级与主操作
- 文案过长是否有省略/换行策略
- 点击热区是否足够
- 深色模式对比度是否可读
- 颜色、字体、圆角、间距是否都来自统一变量体系（而非页面内临时值）

## 5) 设计稿实现成代码（落地阶段）
这一部分回答：如何把设计稿变成 Flutter 代码。

推荐流程：
1. 先抽 token：颜色、字体、圆角、间距
2. 映射到 `AppTheme` / `AppThemeTokens`
3. 先搭页面骨架，再填充组件
4. 接入 provider 状态与 API
5. 补齐交互态、异常态、测试

映射规则：
- 颜色 -> `Theme.of(context).colorScheme` / `context.tokens`
- 字体 -> `TextTheme`
- 圆角 -> `BorderRadius.circular(tokens.radius...)`
- 卡片/输入/按钮 -> 统一走 `ThemeData` 子主题
- 间距 -> 常量化，避免 magic numbers

实现建议：
- 页面文件负责组装，业务逻辑放 provider
- 优先复用 `lib/widgets/` 现有组件
- 新通用 UI 先内部抽象，再评估公共化
- 避免硬编码颜色和字体（尤其页面级样式）

主题关键文件：
- `lib/app.dart`（挂载 light/dark + themeMode）
- `lib/theme/app_theme.dart`（ThemeData 构建）
- `lib/theme/app_tokens.dart`（设计 token 扩展）
- `lib/theme/theme_mode_provider.dart`（主题模式持久化）
- `lib/pages/theme_mode_page.dart`（主题选择页）

补充：
- 服务端模型有 `Config.theme` 字段：`lib/service/api/models/config.dart`
- 当前主主题仍由本地 `themeModeProvider` 驱动

## 6) Cursor / Copilot 规则检查
已检查：`.cursor/rules/`、`.cursorrules`、`.github/copilot-instructions.md`。
当前仓库未发现上述文件；若后续新增，优先级高于本文件建议。

## 7) Agent 快速 checklist
- 不手改 `*.g.dart`
- provider/model 改动后运行 `build_runner`
- 完成后至少执行 `dart format .` + `flutter analyze`
- 涉及逻辑改动时补或更新测试
- 保持最小必要改动，遵循现有架构与命名
