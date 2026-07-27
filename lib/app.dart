import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flycode/l10n/app_localizations.dart';

import 'l10n/app_language.dart';
import 'l10n/l10n.dart';
import 'providers/app_language_provider.dart';
import 'providers/app_lifecycle_provider.dart';
import 'providers/global_event_provider.dart';
import 'providers/session_completion_notification_provider.dart';
import 'providers/shared_preferences_provider.dart';
import 'router.dart';
import 'service/notification/local_notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';
import 'theme/theme_mode_provider.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final GoRouter _router = appRouter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    unawaited(_ensureNotificationPermissionOnStartup());
  }

  Future<void> _ensureNotificationPermissionOnStartup() async {
    final mode = await readSessionCompletionNotificationModeFromStorage(
      () => ref.read(sharedPreferencesProvider.future),
    );
    if (mode == SessionCompletionNotificationMode.none) return;
    if (!mounted) return;
    await ref.read(localNotificationServiceProvider).ensurePermissionPrompted();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleStateProvider.notifier).setState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(globalEventListenerProvider);
    ref.watch(appLifecycleStateProvider);
    ref.listen<SessionCompletionNotificationMode>(
      sessionCompletionNotificationModeProvider,
      (previous, next) {
        if (next == SessionCompletionNotificationMode.none) return;
        unawaited(
          ref.read(localNotificationServiceProvider).ensurePermissionPrompted(),
        );
      },
    );
    final mode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      routerConfig: _router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode.toThemeMode(),
      locale: language.toLocale(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
