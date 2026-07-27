import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FlyCode'**
  String get appTitle;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get chatTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageFollowSystem;

  /// No description provided for @languageSimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageSimplifiedChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsSessionCompletionNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get settingsSessionCompletionNotification;

  /// No description provided for @settingsSectionConnectionModel.
  ///
  /// In en, this message translates to:
  /// **'Connection & Models'**
  String get settingsSectionConnectionModel;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// No description provided for @settingsModel.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get settingsModel;

  /// No description provided for @settingsSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get settingsSectionMore;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeModeTitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @sessionCompletionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get sessionCompletionNotificationTitle;

  /// No description provided for @sessionCompletionNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose when to receive notifications after a session is completed.'**
  String get sessionCompletionNotificationDescription;

  /// No description provided for @sessionCompletionNotificationModeNone.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get sessionCompletionNotificationModeNone;

  /// No description provided for @sessionCompletionNotificationModeBackgroundOnly.
  ///
  /// In en, this message translates to:
  /// **'Only when app is in background'**
  String get sessionCompletionNotificationModeBackgroundOnly;

  /// No description provided for @sessionCompletionNotificationModeAlways.
  ///
  /// In en, this message translates to:
  /// **'Also when app is in foreground'**
  String get sessionCompletionNotificationModeAlways;

  /// No description provided for @mainTabProjects.
  ///
  /// In en, this message translates to:
  /// **'PROJECTS'**
  String get mainTabProjects;

  /// No description provided for @mainTabSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get mainTabSettings;

  /// No description provided for @serverConfigConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Connect Server'**
  String get serverConfigConnectServer;

  /// No description provided for @serverConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Configuration'**
  String get serverConfigTitle;

  /// No description provided for @serverConfigOnboardingHint.
  ///
  /// In en, this message translates to:
  /// **'Please connect to a server on first launch. We recommend testing the connection before saving.'**
  String get serverConfigOnboardingHint;

  /// No description provided for @serverConfigServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverConfigServerAddress;

  /// No description provided for @serverConfigServerAddressHint.
  ///
  /// In en, this message translates to:
  /// **'http://127.0.0.1:4096'**
  String get serverConfigServerAddressHint;

  /// No description provided for @serverConfigUsernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get serverConfigUsernameOptional;

  /// No description provided for @serverConfigPasswordOptional.
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get serverConfigPasswordOptional;

  /// No description provided for @serverConfigPleaseTestBeforeSave.
  ///
  /// In en, this message translates to:
  /// **'Please test the connection successfully before saving.'**
  String get serverConfigPleaseTestBeforeSave;

  /// No description provided for @serverConfigConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get serverConfigConnectionSuccess;

  /// No description provided for @serverConfigSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get serverConfigSaveSuccess;

  /// No description provided for @serverConfigTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get serverConfigTesting;

  /// No description provided for @serverConfigTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get serverConfigTestConnection;

  /// No description provided for @serverConfigSaveAndEnter.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get serverConfigSaveAndEnter;

  /// No description provided for @serverConfigSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get serverConfigSave;

  /// No description provided for @serverConfigValidationServerRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter server URL'**
  String get serverConfigValidationServerRequired;

  /// No description provided for @serverConfigValidationServerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid server URL'**
  String get serverConfigValidationServerInvalid;

  /// No description provided for @serverConfigErrorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your username or password.'**
  String get serverConfigErrorAuthFailed;

  /// No description provided for @serverConfigErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error ({statusCode}), please try again later.'**
  String serverConfigErrorServer(int statusCode);

  /// No description provided for @serverConfigErrorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({statusCode}): {message}'**
  String serverConfigErrorRequestFailed(int statusCode, String message);

  /// No description provided for @serverConfigErrorCannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to server. Please check URL and network.'**
  String get serverConfigErrorCannotConnect;

  /// No description provided for @serverConfigErrorNetworkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Network request failed. Please check server URL.'**
  String get serverConfigErrorNetworkRequestFailed;

  /// No description provided for @serverConfigErrorFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid server URL format'**
  String get serverConfigErrorFormat;

  /// No description provided for @serverConfigErrorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check server configuration.'**
  String get serverConfigErrorConnectionFailed;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep coding within reach. Continue your projects and conversations from your phone.'**
  String get aboutHeroDescription;

  /// No description provided for @aboutSectionProductInfo.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get aboutSectionProductInfo;

  /// No description provided for @aboutOfficialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutOfficialWebsite;

  /// No description provided for @aboutSectionLegalSupport.
  ///
  /// In en, this message translates to:
  /// **'Legal & Support'**
  String get aboutSectionLegalSupport;

  /// No description provided for @aboutCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutCurrentVersion;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacyPolicy;

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link right now'**
  String get aboutOpenLinkFailed;

  /// No description provided for @projectListHeader.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectListHeader;

  /// No description provided for @projectListNew.
  ///
  /// In en, this message translates to:
  /// **'+ New'**
  String get projectListNew;

  /// No description provided for @projectListLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load projects'**
  String get projectListLoadFailedTitle;

  /// No description provided for @projectListGoConfigureServer.
  ///
  /// In en, this message translates to:
  /// **'Configure server'**
  String get projectListGoConfigureServer;

  /// No description provided for @projectListRetryLoad.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get projectListRetryLoad;

  /// No description provided for @projectListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects'**
  String get projectListEmpty;

  /// No description provided for @projectListPleaseAddProject.
  ///
  /// In en, this message translates to:
  /// **'Please add a project first'**
  String get projectListPleaseAddProject;

  /// No description provided for @projectListCheckServerConfig.
  ///
  /// In en, this message translates to:
  /// **'Check server configuration'**
  String get projectListCheckServerConfig;

  /// No description provided for @projectListActionPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get projectListActionPin;

  /// No description provided for @projectListActionUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get projectListActionUnpin;

  /// No description provided for @projectListUpdatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get projectListUpdatedJustNow;

  /// No description provided for @projectListUpdatedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String projectListUpdatedMinutesAgo(int count);

  /// No description provided for @projectListUpdatedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String projectListUpdatedHoursAgo(int count);

  /// No description provided for @projectListUpdatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String projectListUpdatedDaysAgo(int count);

  /// No description provided for @projectListErrorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check server credentials.'**
  String get projectListErrorAuthFailed;

  /// No description provided for @projectListErrorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server temporarily unavailable ({statusCode}).'**
  String projectListErrorServerUnavailable(int statusCode);

  /// No description provided for @projectListErrorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({statusCode}): {message}'**
  String projectListErrorRequestFailed(int statusCode, String message);

  /// No description provided for @projectListErrorCannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to server. Please check URL or network.'**
  String get projectListErrorCannotConnect;

  /// No description provided for @projectListErrorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load projects. Please check server configuration.'**
  String get projectListErrorLoadFailed;

  /// No description provided for @homeNewSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new session'**
  String get homeNewSessionTitle;

  /// No description provided for @homeNewSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type a message below. A session will be created automatically after sending.'**
  String get homeNewSessionSubtitle;

  /// No description provided for @homeTooltipFileDiff.
  ///
  /// In en, this message translates to:
  /// **'File changes'**
  String get homeTooltipFileDiff;

  /// No description provided for @homeTooltipContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get homeTooltipContext;

  /// No description provided for @homeNoSession.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get homeNoSession;

  /// No description provided for @homeSelectSession.
  ///
  /// In en, this message translates to:
  /// **'Select a session'**
  String get homeSelectSession;

  /// No description provided for @messageListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages. Please try again later.'**
  String get messageListLoadFailed;

  /// No description provided for @modelConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Model Configuration'**
  String get modelConfigTitle;

  /// No description provided for @modelConfigRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Model list refreshed'**
  String get modelConfigRefreshed;

  /// No description provided for @modelConfigRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed: {error}'**
  String modelConfigRefreshFailed(String error);

  /// No description provided for @modelConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load model list: {error}'**
  String modelConfigLoadFailed(String error);

  /// No description provided for @modelConfigSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search provider or model'**
  String get modelConfigSearchHint;

  /// No description provided for @modelConfigNoProvider.
  ///
  /// In en, this message translates to:
  /// **'No available providers'**
  String get modelConfigNoProvider;

  /// No description provided for @modelConfigNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching provider or model'**
  String get modelConfigNoMatch;

  /// No description provided for @modelConfigLoadConfigFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load config: {error}'**
  String modelConfigLoadConfigFailed(String error);

  /// No description provided for @modelConfigBatchUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Batch update failed: {error}'**
  String modelConfigBatchUpdateFailed(String error);

  /// No description provided for @modelConfigUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String modelConfigUpdateFailed(String error);

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get commonFavorite;

  /// No description provided for @sessionContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get sessionContextTitle;

  /// No description provided for @sessionContextLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String sessionContextLoadFailed(String error);

  /// No description provided for @sessionContextUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get sessionContextUsed;

  /// No description provided for @sessionContextTotalTokens.
  ///
  /// In en, this message translates to:
  /// **'Total Tokens'**
  String get sessionContextTotalTokens;

  /// No description provided for @sessionContextLimit.
  ///
  /// In en, this message translates to:
  /// **'Context Limit'**
  String get sessionContextLimit;

  /// No description provided for @sessionContextTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get sessionContextTotalCost;

  /// No description provided for @sessionContextInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Info'**
  String get sessionContextInfoTitle;

  /// No description provided for @sessionContextProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get sessionContextProvider;

  /// No description provided for @sessionContextModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get sessionContextModel;

  /// No description provided for @sessionContextUserMessages.
  ///
  /// In en, this message translates to:
  /// **'User Messages'**
  String get sessionContextUserMessages;

  /// No description provided for @sessionContextAssistantMessages.
  ///
  /// In en, this message translates to:
  /// **'Assistant Messages'**
  String get sessionContextAssistantMessages;

  /// No description provided for @sessionContextCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get sessionContextCreatedAt;

  /// No description provided for @sessionContextLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last Active'**
  String get sessionContextLastActive;

  /// No description provided for @sessionDiffTitle.
  ///
  /// In en, this message translates to:
  /// **'File Changes'**
  String get sessionDiffTitle;

  /// No description provided for @sessionDiffLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get sessionDiffLoadFailed;

  /// No description provided for @sessionDiffEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No file changes'**
  String get sessionDiffEmptyTitle;

  /// No description provided for @sessionDiffEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No file changes were produced in this session'**
  String get sessionDiffEmptySubtitle;

  /// No description provided for @sessionDiffFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String sessionDiffFilesCount(int count);

  /// No description provided for @sessionDiffViewFileContent.
  ///
  /// In en, this message translates to:
  /// **'View file content'**
  String get sessionDiffViewFileContent;

  /// No description provided for @sessionDiffEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'(empty file)'**
  String get sessionDiffEmptyFile;

  /// No description provided for @sessionDiffCollapsedLines.
  ///
  /// In en, this message translates to:
  /// **'-- {count} unchanged lines --'**
  String sessionDiffCollapsedLines(int count);

  /// No description provided for @fileContentCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy content'**
  String get fileContentCopyTooltip;

  /// No description provided for @fileContentCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get fileContentCopied;

  /// No description provided for @fileContentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get fileContentLoadFailed;

  /// No description provided for @fileContentLines.
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String fileContentLines(int count);

  /// No description provided for @fileContentPreviewUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Preview is not available for this file'**
  String get fileContentPreviewUnsupported;

  /// No description provided for @fileContentBinary.
  ///
  /// In en, this message translates to:
  /// **'Binary file'**
  String get fileContentBinary;

  /// No description provided for @fileContentBinaryWithMime.
  ///
  /// In en, this message translates to:
  /// **'Binary file ({mimeType})'**
  String fileContentBinaryWithMime(String mimeType);

  /// No description provided for @openProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Project'**
  String get openProjectTitle;

  /// No description provided for @openProjectInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter directory name or path (e.g. ~/projects)'**
  String get openProjectInputHint;

  /// No description provided for @openProjectErrorResolveHome.
  ///
  /// In en, this message translates to:
  /// **'Unable to resolve home directory'**
  String get openProjectErrorResolveHome;

  /// No description provided for @openProjectErrorOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open project: {error}'**
  String openProjectErrorOpenFailed(String error);

  /// No description provided for @openProjectPlaceholderSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by directory name'**
  String get openProjectPlaceholderSearch;

  /// No description provided for @openProjectPlaceholderPathSupport.
  ///
  /// In en, this message translates to:
  /// **'Path navigation supported: ~/projects/myapp'**
  String get openProjectPlaceholderPathSupport;

  /// No description provided for @openProjectNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching directories'**
  String get openProjectNoMatch;

  /// No description provided for @chatInputPickImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select images: {error}'**
  String chatInputPickImageFailed(String error);

  /// No description provided for @chatInputAbortFailed.
  ///
  /// In en, this message translates to:
  /// **'Abort failed: {error}'**
  String chatInputAbortFailed(String error);

  /// No description provided for @chatInputSendError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chatInputSendError(String error);

  /// No description provided for @chatInputShellHint.
  ///
  /// In en, this message translates to:
  /// **'Type a shell command...'**
  String get chatInputShellHint;

  /// No description provided for @chatInputAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything...'**
  String get chatInputAskHint;

  /// No description provided for @chatInputSessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get chatInputSessionHistory;

  /// No description provided for @chatInputNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get chatInputNoSessions;

  /// No description provided for @chatInputToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatInputToday;

  /// No description provided for @chatInputYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatInputYesterday;

  /// No description provided for @chatInputMonthDay.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String chatInputMonthDay(int month, int day);

  /// No description provided for @chatInputJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get chatInputJustNow;

  /// No description provided for @chatInputMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String chatInputMinutesAgo(int count);

  /// No description provided for @chatInputHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String chatInputHoursAgo(int count);

  /// No description provided for @chatInputDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String chatInputDaysAgo(int count);

  /// No description provided for @chatInputSelectVariant.
  ///
  /// In en, this message translates to:
  /// **'Select Variant'**
  String get chatInputSelectVariant;

  /// No description provided for @chatInputSelectAgent.
  ///
  /// In en, this message translates to:
  /// **'Select Agent'**
  String get chatInputSelectAgent;

  /// No description provided for @questionCardSelectOneOrMore.
  ///
  /// In en, this message translates to:
  /// **'Select one or more answers'**
  String get questionCardSelectOneOrMore;

  /// No description provided for @questionCardSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Select one answer'**
  String get questionCardSelectOne;

  /// No description provided for @questionCardIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get questionCardIgnore;

  /// No description provided for @questionCardPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get questionCardPrevious;

  /// No description provided for @questionCardSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get questionCardSubmit;

  /// No description provided for @questionCardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get questionCardNext;

  /// No description provided for @questionCardCustomAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get questionCardCustomAnswerHint;

  /// No description provided for @permissionDockTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Request'**
  String get permissionDockTitle;

  /// No description provided for @permissionDockDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get permissionDockDeny;

  /// No description provided for @permissionDockAllowAlways.
  ///
  /// In en, this message translates to:
  /// **'Allow always'**
  String get permissionDockAllowAlways;

  /// No description provided for @permissionDockAllowOnce.
  ///
  /// In en, this message translates to:
  /// **'Allow once'**
  String get permissionDockAllowOnce;

  /// No description provided for @permissionDockReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Permission reply failed: {error}'**
  String permissionDockReplyFailed(String error);

  /// No description provided for @modelSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get modelSelectionTitle;

  /// No description provided for @modelSelectionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search models'**
  String get modelSelectionSearchHint;

  /// No description provided for @modelSelectionConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Config load failed: {error}'**
  String modelSelectionConfigLoadFailed(String error);

  /// No description provided for @modelSelectionListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Model list load failed: {error}'**
  String modelSelectionListLoadFailed(String error);

  /// No description provided for @modelSelectionNoConnectedProviders.
  ///
  /// In en, this message translates to:
  /// **'No connected model providers'**
  String get modelSelectionNoConnectedProviders;

  /// No description provided for @modelSelectionNoModels.
  ///
  /// In en, this message translates to:
  /// **'No available models'**
  String get modelSelectionNoModels;

  /// No description provided for @modelSelectionNoMatchedModels.
  ///
  /// In en, this message translates to:
  /// **'No matching models'**
  String get modelSelectionNoMatchedModels;

  /// No description provided for @modelSelectionNoModelsUnderProvider.
  ///
  /// In en, this message translates to:
  /// **'No available models under this provider'**
  String get modelSelectionNoModelsUnderProvider;

  /// No description provided for @modelSelectionFavorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get modelSelectionFavorited;

  /// No description provided for @messageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get messageCopy;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get messageCopied;

  /// No description provided for @todoPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Task Plan'**
  String get todoPanelTitle;

  /// No description provided for @todoBadgeInProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} in progress'**
  String todoBadgeInProgress(int count);

  /// No description provided for @todoBadgePending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String todoBadgePending(int count);

  /// No description provided for @todoBadgeCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String todoBadgeCompleted(int count);

  /// No description provided for @todoPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get todoPriorityHigh;

  /// No description provided for @todoPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get todoPriorityMedium;

  /// No description provided for @todoPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get todoPriorityLow;

  /// No description provided for @sessionCompletedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Session completed'**
  String get sessionCompletedNotificationTitle;

  /// No description provided for @sessionCompletedNotificationBodyWithTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} has completed'**
  String sessionCompletedNotificationBodyWithTitle(String title);

  /// No description provided for @sessionCompletedNotificationBodyWithoutTitle.
  ///
  /// In en, this message translates to:
  /// **'A session has completed'**
  String get sessionCompletedNotificationBodyWithoutTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
