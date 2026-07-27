// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FlyCode';

  @override
  String get chatTitle => 'Session';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String get languageSimplifiedChinese => 'Simplified Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsSessionCompletionNotification => 'Notification';

  @override
  String get settingsSectionConnectionModel => 'Connection & Models';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsModel => 'Models';

  @override
  String get settingsSectionMore => 'More';

  @override
  String get settingsAbout => 'About';

  @override
  String get themeModeTitle => 'Theme';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get sessionCompletionNotificationTitle => 'Notification';

  @override
  String get sessionCompletionNotificationDescription =>
      'Choose when to receive notifications after a session is completed.';

  @override
  String get sessionCompletionNotificationModeNone => 'Never';

  @override
  String get sessionCompletionNotificationModeBackgroundOnly =>
      'Only when app is in background';

  @override
  String get sessionCompletionNotificationModeAlways =>
      'Also when app is in foreground';

  @override
  String get mainTabProjects => 'PROJECTS';

  @override
  String get mainTabSettings => 'SETTINGS';

  @override
  String get serverConfigConnectServer => 'Connect Server';

  @override
  String get serverConfigTitle => 'Server Configuration';

  @override
  String get serverConfigOnboardingHint =>
      'Please connect to a server on first launch. We recommend testing the connection before saving.';

  @override
  String get serverConfigServerAddress => 'Server URL';

  @override
  String get serverConfigServerAddressHint => 'http://127.0.0.1:4096';

  @override
  String get serverConfigUsernameOptional => 'Username (optional)';

  @override
  String get serverConfigPasswordOptional => 'Password (optional)';

  @override
  String get serverConfigPleaseTestBeforeSave =>
      'Please test the connection successfully before saving.';

  @override
  String get serverConfigConnectionSuccess => 'Connection successful';

  @override
  String get serverConfigSaveSuccess => 'Saved';

  @override
  String get serverConfigTesting => 'Testing...';

  @override
  String get serverConfigTestConnection => 'Test Connection';

  @override
  String get serverConfigSaveAndEnter => 'Save & Continue';

  @override
  String get serverConfigSave => 'Save';

  @override
  String get serverConfigValidationServerRequired => 'Please enter server URL';

  @override
  String get serverConfigValidationServerInvalid =>
      'Please enter a valid server URL';

  @override
  String get serverConfigErrorAuthFailed =>
      'Authentication failed. Please check your username or password.';

  @override
  String serverConfigErrorServer(int statusCode) {
    return 'Server error ($statusCode), please try again later.';
  }

  @override
  String serverConfigErrorRequestFailed(int statusCode, String message) {
    return 'Request failed ($statusCode): $message';
  }

  @override
  String get serverConfigErrorCannotConnect =>
      'Unable to connect to server. Please check URL and network.';

  @override
  String get serverConfigErrorNetworkRequestFailed =>
      'Network request failed. Please check server URL.';

  @override
  String get serverConfigErrorFormat => 'Invalid server URL format';

  @override
  String get serverConfigErrorConnectionFailed =>
      'Connection failed. Please check server configuration.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutHeroDescription =>
      'Keep coding within reach. Continue your projects and conversations from your phone.';

  @override
  String get aboutSectionProductInfo => 'Product';

  @override
  String get aboutOfficialWebsite => 'Website';

  @override
  String get aboutSectionLegalSupport => 'Legal & Support';

  @override
  String get aboutCurrentVersion => 'Version';

  @override
  String get aboutPrivacyPolicy => 'Privacy Policy';

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutOpenLinkFailed => 'Unable to open link right now';

  @override
  String get projectListHeader => 'Projects';

  @override
  String get projectListNew => '+ New';

  @override
  String get projectListLoadFailedTitle => 'Unable to load projects';

  @override
  String get projectListGoConfigureServer => 'Configure server';

  @override
  String get projectListRetryLoad => 'Retry';

  @override
  String get projectListEmpty => 'No projects';

  @override
  String get projectListPleaseAddProject => 'Please add a project first';

  @override
  String get projectListCheckServerConfig => 'Check server configuration';

  @override
  String get projectListActionPin => 'Pin';

  @override
  String get projectListActionUnpin => 'Unpin';

  @override
  String get projectListUpdatedJustNow => 'Just now';

  @override
  String projectListUpdatedMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String projectListUpdatedHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String projectListUpdatedDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get projectListErrorAuthFailed =>
      'Authentication failed. Please check server credentials.';

  @override
  String projectListErrorServerUnavailable(int statusCode) {
    return 'Server temporarily unavailable ($statusCode).';
  }

  @override
  String projectListErrorRequestFailed(int statusCode, String message) {
    return 'Request failed ($statusCode): $message';
  }

  @override
  String get projectListErrorCannotConnect =>
      'Unable to connect to server. Please check URL or network.';

  @override
  String get projectListErrorLoadFailed =>
      'Failed to load projects. Please check server configuration.';

  @override
  String get homeNewSessionTitle => 'Start a new session';

  @override
  String get homeNewSessionSubtitle =>
      'Type a message below. A session will be created automatically after sending.';

  @override
  String get homeTooltipFileDiff => 'File changes';

  @override
  String get homeTooltipContext => 'Context';

  @override
  String get homeNoSession => 'No sessions';

  @override
  String get homeSelectSession => 'Select a session';

  @override
  String get messageListLoadFailed =>
      'Failed to load messages. Please try again later.';

  @override
  String get modelConfigTitle => 'Model Configuration';

  @override
  String get modelConfigRefreshed => 'Model list refreshed';

  @override
  String modelConfigRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String modelConfigLoadFailed(String error) {
    return 'Failed to load model list: $error';
  }

  @override
  String get modelConfigSearchHint => 'Search provider or model';

  @override
  String get modelConfigNoProvider => 'No available providers';

  @override
  String get modelConfigNoMatch => 'No matching provider or model';

  @override
  String modelConfigLoadConfigFailed(String error) {
    return 'Failed to load config: $error';
  }

  @override
  String modelConfigBatchUpdateFailed(String error) {
    return 'Batch update failed: $error';
  }

  @override
  String modelConfigUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get commonAll => 'All';

  @override
  String get commonFavorite => 'Favorite';

  @override
  String get sessionContextTitle => 'Context';

  @override
  String sessionContextLoadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get sessionContextUsed => 'Used';

  @override
  String get sessionContextTotalTokens => 'Total Tokens';

  @override
  String get sessionContextLimit => 'Context Limit';

  @override
  String get sessionContextTotalCost => 'Total Cost';

  @override
  String get sessionContextInfoTitle => 'Session Info';

  @override
  String get sessionContextProvider => 'Provider';

  @override
  String get sessionContextModel => 'Model';

  @override
  String get sessionContextUserMessages => 'User Messages';

  @override
  String get sessionContextAssistantMessages => 'Assistant Messages';

  @override
  String get sessionContextCreatedAt => 'Created At';

  @override
  String get sessionContextLastActive => 'Last Active';

  @override
  String get sessionDiffTitle => 'File Changes';

  @override
  String get sessionDiffLoadFailed => 'Load failed';

  @override
  String get sessionDiffEmptyTitle => 'No file changes';

  @override
  String get sessionDiffEmptySubtitle =>
      'No file changes were produced in this session';

  @override
  String sessionDiffFilesCount(int count) {
    return '$count files';
  }

  @override
  String get sessionDiffViewFileContent => 'View file content';

  @override
  String get sessionDiffEmptyFile => '(empty file)';

  @override
  String sessionDiffCollapsedLines(int count) {
    return '-- $count unchanged lines --';
  }

  @override
  String get fileContentCopyTooltip => 'Copy content';

  @override
  String get fileContentCopied => 'Copied to clipboard';

  @override
  String get fileContentLoadFailed => 'Load failed';

  @override
  String fileContentLines(int count) {
    return '$count lines';
  }

  @override
  String get fileContentPreviewUnsupported =>
      'Preview is not available for this file';

  @override
  String get fileContentBinary => 'Binary file';

  @override
  String fileContentBinaryWithMime(String mimeType) {
    return 'Binary file ($mimeType)';
  }

  @override
  String get openProjectTitle => 'Open Project';

  @override
  String get openProjectInputHint =>
      'Enter directory name or path (e.g. ~/projects)';

  @override
  String get openProjectErrorResolveHome => 'Unable to resolve home directory';

  @override
  String openProjectErrorOpenFailed(String error) {
    return 'Failed to open project: $error';
  }

  @override
  String get openProjectPlaceholderSearch => 'Search by directory name';

  @override
  String get openProjectPlaceholderPathSupport =>
      'Path navigation supported: ~/projects/myapp';

  @override
  String get openProjectNoMatch => 'No matching directories';

  @override
  String chatInputPickImageFailed(String error) {
    return 'Failed to select images: $error';
  }

  @override
  String chatInputAbortFailed(String error) {
    return 'Abort failed: $error';
  }

  @override
  String chatInputSendError(String error) {
    return 'Error: $error';
  }

  @override
  String get chatInputShellHint => 'Type a shell command...';

  @override
  String get chatInputAskHint => 'Ask anything...';

  @override
  String get chatInputSessionHistory => 'Session History';

  @override
  String get chatInputNoSessions => 'No sessions';

  @override
  String get chatInputToday => 'Today';

  @override
  String get chatInputYesterday => 'Yesterday';

  @override
  String chatInputMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String get chatInputJustNow => 'Just now';

  @override
  String chatInputMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String chatInputHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String chatInputDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get chatInputSelectVariant => 'Select Variant';

  @override
  String get chatInputSelectAgent => 'Select Agent';

  @override
  String get questionCardSelectOneOrMore => 'Select one or more answers';

  @override
  String get questionCardSelectOne => 'Select one answer';

  @override
  String get questionCardIgnore => 'Ignore';

  @override
  String get questionCardPrevious => 'Previous';

  @override
  String get questionCardSubmit => 'Submit';

  @override
  String get questionCardNext => 'Next';

  @override
  String get questionCardCustomAnswerHint => 'Type your answer...';

  @override
  String get permissionDockTitle => 'Permission Request';

  @override
  String get permissionDockDeny => 'Deny';

  @override
  String get permissionDockAllowAlways => 'Allow always';

  @override
  String get permissionDockAllowOnce => 'Allow once';

  @override
  String permissionDockReplyFailed(String error) {
    return 'Permission reply failed: $error';
  }

  @override
  String get modelSelectionTitle => 'Select Model';

  @override
  String get modelSelectionSearchHint => 'Search models';

  @override
  String modelSelectionConfigLoadFailed(String error) {
    return 'Config load failed: $error';
  }

  @override
  String modelSelectionListLoadFailed(String error) {
    return 'Model list load failed: $error';
  }

  @override
  String get modelSelectionNoConnectedProviders =>
      'No connected model providers';

  @override
  String get modelSelectionNoModels => 'No available models';

  @override
  String get modelSelectionNoMatchedModels => 'No matching models';

  @override
  String get modelSelectionNoModelsUnderProvider =>
      'No available models under this provider';

  @override
  String get modelSelectionFavorited => 'Favorited';

  @override
  String get messageCopy => 'Copy';

  @override
  String get messageCopied => 'Copied';

  @override
  String get todoPanelTitle => 'AI Task Plan';

  @override
  String todoBadgeInProgress(int count) {
    return '$count in progress';
  }

  @override
  String todoBadgePending(int count) {
    return '$count pending';
  }

  @override
  String todoBadgeCompleted(int count) {
    return '$count completed';
  }

  @override
  String get todoPriorityHigh => 'High';

  @override
  String get todoPriorityMedium => 'Medium';

  @override
  String get todoPriorityLow => 'Low';

  @override
  String get sessionCompletedNotificationTitle => 'Session completed';

  @override
  String sessionCompletedNotificationBodyWithTitle(String title) {
    return '$title has completed';
  }

  @override
  String get sessionCompletedNotificationBodyWithoutTitle =>
      'A session has completed';
}
