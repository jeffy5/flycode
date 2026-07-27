# Changelog

## v2.0.0 — 性能优化 + 新功能 (2026-07-27)

### 体验优化
- **跳过首次连接配置**：直接进入项目列表页，默认连接 `http://127.0.0.1:4096`，地址可在设置中修改

### 性能优化
- **最小粒度消息更新**：SSE delta 不再重建整个消息列表，改用 `ValueNotifier` 只更新对应的单条消息气泡（`session_provider.dart` + `message_list.dart`）
- **打字机动画降频**：从 24ms → 100ms，减少 75% markdown 重渲染（`message_part.dart`）
- **ListView 缓存**：`cacheExtent: 500` 预构建离屏 item（`message_list.dart`）
- **didUpdateWidget 跳过**：消息数量不变时跳过签名计算，流式更新几乎零开销（`message_list.dart`）
- **签名计算优化**：`_messageListSignature` 和 `_didBottomAffectingContentChange` 改为线性扫描，不创建中间 List 拷贝

### 消息加载与缓存
- **分页加载**：首次只拉 30 条，滑到顶部距边缘 80px 自动触发加载更多（`session_provider.dart`）
- **HTTP 超时 15s → 60s**：大会话请求不再超时（`session_api.dart`）
- **sqflite 本地缓存**：首次加载后缓存到本地数据库，冷启动直接出内容，零网络；`keepAlive()` 防止会话切换时 provider 销毁（`database_helper.dart` + `session_provider.dart`）

### 新功能
- **文件浏览器**：浏览项目目录树，点击查看文件内容，支持跨目录浏览（`file_browser_page.dart`）
- **长按复制路径**：文件/文件夹长按复制绝对路径到剪贴板（`file_browser_page.dart`）
- **删除会话**：会话列表左滑删除 + 确认弹窗（`chat_input.dart`）
- **重命名会话**：会话列表长按 → 输入新名称 → PATCH API（`chat_input.dart`）
- **文件浏览入口**：AppBar 📁 按钮（`home_page.dart`）
- **Todo 默认折叠**：不挡聊天视野（`todo_list_widget.dart`）

### Bug 修复
- **加载更多后不显示**：`loadMore` 后清空 `_frozenMessages`，新消息立刻可见（`message_list.dart`）
- **返回上一级目录不加载**：`_navigateUp` 改用绝对路径 + `listDirectory` 恢复正确参数（`file_browser_page.dart` + `file_api.dart`）
- **跨目录读文件**：去掉 `x-opencode-directory` header 限制，工作目录内外均可读（`file_api.dart`）
- **大上下文超时**：`limit: 30` + 60s 超时，大会话不再加载失败

## v1.0.0 — 初始版本
- 原版 flycode：Android/iOS 移动客户端，连接 opencode server
- 功能：项目浏览、会话管理、消息对话、权限请求、Todo、Diff、上下文查看
- 主题：暗色/亮色


## v1.0.0 - 2026-04-09

### Added
- Initial public release of FlyCode, a Flutter mobile client for connecting to `opencode server`.
- Project browsing and session management for quickly jumping into new or existing coding sessions.
- Mobile-optimized chat experience for interacting with coding agents, including streaming responses and markdown rendering.
- In-app support for reviewing permission requests, interactive questions, todos, diffs, and session context.
- Model and agent configuration, including provider-aware model selection and variant switching.
- File and image input workflows, including `@` file mentions, image attachments, and clipboard image paste support.
- Local persistence for app settings and session-related preferences, plus optional session completion notifications.
- Built-in app personalization with theme mode selection and multilingual localization support.
