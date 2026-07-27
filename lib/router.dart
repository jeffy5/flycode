import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'models/chat_route_args.dart';
import 'models/typed_route_args.dart';
import 'pages/app_entry_page.dart';
import 'pages/about_page.dart';
import 'pages/file_content_page.dart';
import 'pages/home_page.dart';
import 'pages/language_page.dart';
import 'pages/project_list_page.dart';
import 'pages/session_context_page.dart';
import 'pages/session_diff_page.dart';
import 'pages/settings_page.dart';
import 'pages/theme_mode_page.dart';
import 'pages/server_config_page.dart';
import 'pages/model_config_page.dart';
import 'pages/session_completion_notification_page.dart';
import 'pages/sub_session_page.dart';
import 'models/server_config.dart';
import 'route_navigation.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const AppEntryPage()),
    GoRoute(
      path: '/chat',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as ChatRouteArgs?;
        return MyHomePage(title: context.l10n.chatTitle, args: args);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/settings/theme',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ThemeModePage(),
    ),
    GoRoute(
      path: '/settings/language',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LanguagePage(),
    ),
    GoRoute(
      path: '/settings/server',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final config = state.extra as ServerConfig?;
        return ServerConfigPage(initialConfig: config);
      },
    ),
    GoRoute(
      path: '/settings/model',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ModelConfigPage(),
    ),
    GoRoute(
      path: '/settings/session-completion-notification',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SessionCompletionNotificationPage(),
    ),
    GoRoute(
      path: '/settings/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/projects',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProjectListPage(),
    ),
    GoRoute(
      path: sessionDiffRoutePath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as SessionDiffRouteArgs;
        return SessionDiffPage(sessionID: args.sessionID);
      },
    ),
    GoRoute(
      path: fileContentRoutePath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as FileContentRouteArgs;
        return FileContentPage(filePath: args.filePath);
      },
    ),
    GoRoute(
      path: subSessionRoutePath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as SubSessionRouteArgs;
        return SubSessionPage(sessionID: args.sessionID);
      },
    ),
    GoRoute(
      path: sessionContextRoutePath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as SessionContextRouteArgs;
        return SessionContextPage(sessionID: args.sessionID);
      },
    ),
  ],
);
