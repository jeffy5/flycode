// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'FlyCode';

  @override
  String get chatTitle => '会话';

  @override
  String get languageTitle => '语言';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionGeneral => '通用设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsTheme => '色彩主题';

  @override
  String get settingsSessionCompletionNotification => '通知';

  @override
  String get settingsSectionConnectionModel => '连接与模型';

  @override
  String get settingsServer => '服务器';

  @override
  String get settingsModel => '模型';

  @override
  String get settingsSectionMore => '更多';

  @override
  String get settingsAbout => '关于';

  @override
  String get themeModeTitle => '色彩主题';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get sessionCompletionNotificationTitle => '通知';

  @override
  String get sessionCompletionNotificationDescription => '设置会话完成后何时向你发送通知。';

  @override
  String get sessionCompletionNotificationModeNone => '不发送通知';

  @override
  String get sessionCompletionNotificationModeBackgroundOnly => '应用在后台时发送通知';

  @override
  String get sessionCompletionNotificationModeAlways => '应用在前台时也发送通知';

  @override
  String get mainTabProjects => '项目';

  @override
  String get mainTabSettings => '设置';

  @override
  String get serverConfigConnectServer => '连接服务器';

  @override
  String get serverConfigTitle => '服务器配置';

  @override
  String get serverConfigOnboardingHint => '首次使用请先连接服务器。建议先点击“测试连接”，再保存进入首页。';

  @override
  String get serverConfigServerAddress => '服务器地址';

  @override
  String get serverConfigServerAddressHint => 'http://127.0.0.1:4096';

  @override
  String get serverConfigUsernameOptional => '用户名（可选）';

  @override
  String get serverConfigPasswordOptional => '密码（可选）';

  @override
  String get serverConfigPleaseTestBeforeSave => '请先测试连接并成功后再保存';

  @override
  String get serverConfigConnectionSuccess => '连接成功';

  @override
  String get serverConfigSaveSuccess => '保存成功';

  @override
  String get serverConfigTesting => '测试中...';

  @override
  String get serverConfigTestConnection => '测试连接';

  @override
  String get serverConfigSaveAndEnter => '保存并进入';

  @override
  String get serverConfigSave => '保存';

  @override
  String get serverConfigValidationServerRequired => '请输入服务器地址';

  @override
  String get serverConfigValidationServerInvalid => '请输入有效的服务器地址';

  @override
  String get serverConfigErrorAuthFailed => '认证失败，请检查用户名或密码';

  @override
  String serverConfigErrorServer(int statusCode) {
    return '服务器异常（$statusCode），请稍后重试';
  }

  @override
  String serverConfigErrorRequestFailed(int statusCode, String message) {
    return '请求失败（$statusCode）：$message';
  }

  @override
  String get serverConfigErrorCannotConnect => '无法连接到服务器，请检查地址和网络';

  @override
  String get serverConfigErrorNetworkRequestFailed => '网络请求失败，请检查服务器地址';

  @override
  String get serverConfigErrorFormat => '服务器地址格式不正确';

  @override
  String get serverConfigErrorConnectionFailed => '连接失败，请检查服务器配置';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutHeroDescription => '让 coding 随时发生。你可以在手机上继续项目、衔接会话与灵感。';

  @override
  String get aboutSectionProductInfo => '产品信息';

  @override
  String get aboutOfficialWebsite => '官网';

  @override
  String get aboutSectionLegalSupport => '法律与支持';

  @override
  String get aboutCurrentVersion => '当前版本';

  @override
  String get aboutPrivacyPolicy => '隐私政策';

  @override
  String get aboutOpenSourceLicenses => '开源许可';

  @override
  String get aboutOpenLinkFailed => '暂时无法打开链接';

  @override
  String get projectListHeader => '项目';

  @override
  String get projectListNew => '+ 新建';

  @override
  String get projectListLoadFailedTitle => '暂时无法加载项目';

  @override
  String get projectListGoConfigureServer => '去配置服务器';

  @override
  String get projectListRetryLoad => '重试加载';

  @override
  String get projectListEmpty => '暂无项目';

  @override
  String get projectListPleaseAddProject => '请先添加一个项目';

  @override
  String get projectListCheckServerConfig => '检查服务器配置';

  @override
  String get projectListActionPin => '置顶';

  @override
  String get projectListActionUnpin => '取消置顶';

  @override
  String get projectListUpdatedJustNow => '刚刚';

  @override
  String projectListUpdatedMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String projectListUpdatedHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String projectListUpdatedDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get projectListErrorAuthFailed => '认证失败，请检查服务器账号和密码。';

  @override
  String projectListErrorServerUnavailable(int statusCode) {
    return '服务器暂时不可用（$statusCode）。';
  }

  @override
  String projectListErrorRequestFailed(int statusCode, String message) {
    return '请求失败（$statusCode）：$message';
  }

  @override
  String get projectListErrorCannotConnect => '无法连接到服务器，请检查地址或网络。';

  @override
  String get projectListErrorLoadFailed => '加载项目失败，请检查服务器配置。';

  @override
  String get homeNewSessionTitle => '开始一段新会话';

  @override
  String get homeNewSessionSubtitle => '在下方输入消息，发送后将自动创建会话';

  @override
  String get homeTooltipFileDiff => '文件变更';

  @override
  String get homeTooltipContext => '上下文';

  @override
  String get homeNoSession => '暂无会话';

  @override
  String get homeSelectSession => '请选择一个会话';

  @override
  String get messageListLoadFailed => '消息加载失败，请稍后重试';

  @override
  String get modelConfigTitle => '模型配置';

  @override
  String get modelConfigRefreshed => '模型列表已刷新';

  @override
  String modelConfigRefreshFailed(String error) {
    return '刷新失败: $error';
  }

  @override
  String modelConfigLoadFailed(String error) {
    return '加载模型列表失败: $error';
  }

  @override
  String get modelConfigSearchHint => '搜索 Provider 或模型';

  @override
  String get modelConfigNoProvider => '当前没有可用的 Provider';

  @override
  String get modelConfigNoMatch => '没有匹配的 Provider 或模型';

  @override
  String modelConfigLoadConfigFailed(String error) {
    return '加载配置失败: $error';
  }

  @override
  String modelConfigBatchUpdateFailed(String error) {
    return '批量更新失败: $error';
  }

  @override
  String modelConfigUpdateFailed(String error) {
    return '更新失败: $error';
  }

  @override
  String get commonAll => '全部';

  @override
  String get commonFavorite => '收藏';

  @override
  String get sessionContextTitle => '上下文';

  @override
  String sessionContextLoadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String get sessionContextUsed => '已使用';

  @override
  String get sessionContextTotalTokens => '总 Token';

  @override
  String get sessionContextLimit => '上下文限制';

  @override
  String get sessionContextTotalCost => '总费用';

  @override
  String get sessionContextInfoTitle => '会话信息';

  @override
  String get sessionContextProvider => '提供商';

  @override
  String get sessionContextModel => '模型';

  @override
  String get sessionContextUserMessages => '用户消息';

  @override
  String get sessionContextAssistantMessages => '助手消息';

  @override
  String get sessionContextCreatedAt => '创建时间';

  @override
  String get sessionContextLastActive => '最后活动';

  @override
  String get sessionDiffTitle => '文件变更';

  @override
  String get sessionDiffLoadFailed => '加载失败';

  @override
  String get sessionDiffEmptyTitle => '暂无文件变更';

  @override
  String get sessionDiffEmptySubtitle => '本次会话未产生任何文件改动';

  @override
  String sessionDiffFilesCount(int count) {
    return '$count 个文件';
  }

  @override
  String get sessionDiffViewFileContent => '查看文件内容';

  @override
  String get sessionDiffEmptyFile => '（空文件）';

  @override
  String sessionDiffCollapsedLines(int count) {
    return '── $count 行未变更 ──';
  }

  @override
  String get fileContentCopyTooltip => '复制内容';

  @override
  String get fileContentCopied => '已复制到剪贴板';

  @override
  String get fileContentLoadFailed => '加载失败';

  @override
  String fileContentLines(int count) {
    return '$count 行';
  }

  @override
  String get fileContentPreviewUnsupported => '不支持预览此文件';

  @override
  String get fileContentBinary => '二进制文件';

  @override
  String fileContentBinaryWithMime(String mimeType) {
    return '二进制文件（$mimeType）';
  }

  @override
  String get openProjectTitle => '打开项目';

  @override
  String get openProjectInputHint => '输入目录名称或路径（如 ~/projects）';

  @override
  String get openProjectErrorResolveHome => '无法解析 home 目录';

  @override
  String openProjectErrorOpenFailed(String error) {
    return '打开项目失败：$error';
  }

  @override
  String get openProjectPlaceholderSearch => '输入目录名称进行搜索';

  @override
  String get openProjectPlaceholderPathSupport => '支持路径导航：~/projects/myapp';

  @override
  String get openProjectNoMatch => '未找到匹配的目录';

  @override
  String chatInputPickImageFailed(String error) {
    return '选择图片失败: $error';
  }

  @override
  String chatInputAbortFailed(String error) {
    return '中断失败: $error';
  }

  @override
  String chatInputSendError(String error) {
    return '错误: $error';
  }

  @override
  String get chatInputShellHint => '输入 shell 命令...';

  @override
  String get chatInputAskHint => '随便问点什么...';

  @override
  String get chatInputSessionHistory => '会话历史';

  @override
  String get chatInputNoSessions => '暂无会话';

  @override
  String get chatInputToday => '今天';

  @override
  String get chatInputYesterday => '昨天';

  @override
  String chatInputMonthDay(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get chatInputJustNow => '刚刚';

  @override
  String chatInputMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String chatInputHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String chatInputDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get chatInputSelectVariant => '选择变体';

  @override
  String get chatInputSelectAgent => '选择 Agent';

  @override
  String get questionCardSelectOneOrMore => '选择一个或多个答案';

  @override
  String get questionCardSelectOne => '选择一个答案';

  @override
  String get questionCardIgnore => '忽略';

  @override
  String get questionCardPrevious => '上一步';

  @override
  String get questionCardSubmit => '提交';

  @override
  String get questionCardNext => '下一步';

  @override
  String get questionCardCustomAnswerHint => '输入你的答案...';

  @override
  String get permissionDockTitle => '权限请求';

  @override
  String get permissionDockDeny => '拒绝';

  @override
  String get permissionDockAllowAlways => '始终允许';

  @override
  String get permissionDockAllowOnce => '允许一次';

  @override
  String permissionDockReplyFailed(String error) {
    return '权限响应失败：$error';
  }

  @override
  String get modelSelectionTitle => '选择模型';

  @override
  String get modelSelectionSearchHint => '搜索模型';

  @override
  String modelSelectionConfigLoadFailed(String error) {
    return '配置加载失败: $error';
  }

  @override
  String modelSelectionListLoadFailed(String error) {
    return '模型列表加载失败: $error';
  }

  @override
  String get modelSelectionNoConnectedProviders => '没有连接的模型提供商';

  @override
  String get modelSelectionNoModels => '没有可用的模型';

  @override
  String get modelSelectionNoMatchedModels => '没有匹配的模型';

  @override
  String get modelSelectionNoModelsUnderProvider => '该提供商下没有可用模型';

  @override
  String get modelSelectionFavorited => '已收藏';

  @override
  String get messageCopy => '复制';

  @override
  String get messageCopied => '已复制';

  @override
  String get todoPanelTitle => 'AI 任务规划';

  @override
  String todoBadgeInProgress(int count) {
    return '$count 进行中';
  }

  @override
  String todoBadgePending(int count) {
    return '$count 待处理';
  }

  @override
  String todoBadgeCompleted(int count) {
    return '$count 已完成';
  }

  @override
  String get todoPriorityHigh => '高优';

  @override
  String get todoPriorityMedium => '中';

  @override
  String get todoPriorityLow => '低';

  @override
  String get sessionCompletedNotificationTitle => '会话已完成';

  @override
  String sessionCompletedNotificationBodyWithTitle(String title) {
    return '$title 已完成';
  }

  @override
  String get sessionCompletedNotificationBodyWithoutTitle => '有一个会话已完成';
}
