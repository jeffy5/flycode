import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flycode/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_notification_service.g.dart';

@Riverpod(keepAlive: true)
LocalNotificationService localNotificationService(Ref ref) {
  return LocalNotificationService(FlutterLocalNotificationsPlugin());
}

class LocalNotificationService {
  LocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  bool _permissionsRequested = false;

  static const String _channelId = 'session_completion';
  static const String _channelName = 'Session Completion';
  static const String _channelDescription =
      'Notifications for completed chat sessions';

  Future<void> ensurePermissionPrompted() async {
    await _ensureInitialized();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      if (enabled ?? false) {
        _permissionsRequested = true;
        return;
      }
    }

    await _requestPermissionsIfNeeded();
  }

  Future<void> showSessionCompleted({String? sessionTitle}) async {
    await ensurePermissionPrompted();
    final l10n = await _resolveLocalizations();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final normalizedTitle = sessionTitle?.trim();
    final body = (normalizedTitle != null && normalizedTitle.isNotEmpty)
        ? l10n.sessionCompletedNotificationBodyWithTitle(normalizedTitle)
        : l10n.sessionCompletedNotificationBodyWithoutTitle;
    final id = (normalizedTitle ?? body).hashCode & 0x7fffffff;
    await _plugin.show(
      id,
      l10n.sessionCompletedNotificationTitle,
      body,
      details,
    );
  }

  Future<AppLocalizations> _resolveLocalizations() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return AppLocalizations.delegate.load(locale);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> _requestPermissionsIfNeeded() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macOS = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macOS?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
