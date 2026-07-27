import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import '../models/chat_route_args.dart';
import '../providers/chat_view_state_provider.dart';
import '../providers/current_directory_provider.dart';
import '../providers/home_page_provider.dart';
import '../route_navigation.dart';
import '../service/api/api_client.dart';
import '../theme/app_tokens.dart';
import '../widgets/message/message_list.dart';
import '../widgets/message/chat_input.dart';
import '../widgets/message/chat_command_popup.dart';
import '../widgets/permission/session_permission_dock.dart';
import '../widgets/question/question_card.dart';
import '../widgets/session/todo_list_widget.dart';

String _homeSessionLoadErrorText(BuildContext context, Object? error) {
  final l10n = context.l10n;
  if (error is ApiException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return l10n.projectListErrorAuthFailed;
    }
    if (error.statusCode >= 500) {
      return l10n.projectListErrorServerUnavailable(error.statusCode);
    }
    return l10n.projectListErrorRequestFailed(error.statusCode, error.message);
  }
  if (error is SocketException || error is http.ClientException) {
    return l10n.projectListErrorCannotConnect;
  }
  return l10n.projectListErrorLoadFailed;
}

String? _directoryTitle(String? directory) {
  if (directory == null || directory.isEmpty) return null;
  final parts = directory.replaceAll('\\', '/').split('/');
  return parts.lastWhere((part) => part.isNotEmpty, orElse: () => directory);
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title, this.args});

  final String title;
  final ChatRouteArgs? args;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final CommandPanelController _commandPanelController =
      CommandPanelController();
  final GlobalKey<ChatInputState> _chatInputKey = GlobalKey<ChatInputState>();
  late final ProviderSubscription<bool> _commandPanelAvailabilitySubscription;

  @override
  void initState() {
    super.initState();
    _commandPanelAvailabilitySubscription = ref.listenManual<bool>(
      homePagePresentationStateProvider.select(
        (state) => state.canShowCommandPanel,
      ),
      (previous, next) {
        if (next || !_commandPanelController.visible) {
          return;
        }
        _commandPanelController.hide();
      },
    );
    _scheduleBootstrap();
  }

  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_routeArgsChanged(oldWidget.args, widget.args)) {
      _scheduleBootstrap();
    }
  }

  void _scheduleBootstrap() {
    Future<void>.microtask(() async {
      if (!mounted) {
        return;
      }
      await _bootstrapHomePage();
    });
  }

  Future<void> _bootstrapHomePage() async {
    await ref
        .read(homePageBootstrapControllerProvider.notifier)
        .bootstrap(widget.args);
  }

  bool _routeArgsChanged(ChatRouteArgs? previous, ChatRouteArgs? next) {
    return previous?.directory != next?.directory ||
        previous?.initialSessionId != next?.initialSessionId ||
        previous?.startNew != next?.startNew;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    final homeState = ref.watch(homePagePresentationStateProvider);
    final currentDirectory = ref.watch(currentDirectoryProvider);
    final title = _directoryTitle(currentDirectory);
    final selectedSession = homeState.selectedSession;

    Widget buildNewSessionWelcome() {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: tokens.mutedForeground.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.homeNewSessionTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeNewSessionSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: tokens.mutedForeground.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildBodyContent() {
      switch (homeState.bodyMode) {
        case HomePageBodyMode.messageList:
          return MessageList(
            sessionID: selectedSession!.id,
            onNavigateToSubSession: (sessionId) =>
                context.pushSubSessionById(sessionId),
          );
        case HomePageBodyMode.newSessionWelcome:
          return buildNewSessionWelcome();
        case HomePageBodyMode.sessionSelection:
          final text = homeState.hasAnySessions
              ? l10n.homeSelectSession
              : l10n.homeNoSession;
          return Center(
            child: Text(text, style: TextStyle(color: tokens.mutedForeground)),
          );
        case HomePageBodyMode.loading:
          return const Center(child: CircularProgressIndicator());
        case HomePageBodyMode.error:
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _homeSessionLoadErrorText(context, homeState.loadError),
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.mutedForeground),
              ),
            ),
          );
      }
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        ref.read(homePageBootstrapControllerProvider.notifier).reset();
        ref.read(chatViewStateProvider.notifier).clear();
        ref.read(currentDirectoryProvider.notifier).clear();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 4,
          title: title == null ? null : Text(title),
          actions: [
            if (selectedSession != null) ...[
              _HeaderActionButton(
                icon: Icons.difference_outlined,
                tooltip: l10n.homeTooltipFileDiff,
                onTap: () => context.pushSessionDiffById(selectedSession.id),
              ),
              const SizedBox(width: 8),
              _HeaderActionButton(
                icon: Icons.info_outline,
                tooltip: l10n.homeTooltipContext,
                onTap: () => context.pushSessionContextById(selectedSession.id),
              ),
              const SizedBox(width: 12),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tokens.border.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (selectedSession != null)
                  TodoListWidget(sessionID: selectedSession.id),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _commandPanelController,
                    builder: (context, _) => Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _commandPanelController.visible,
                            child: buildBodyContent(),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !_commandPanelController.visible,
                            child: ChatCommandPopup(
                              controller: _commandPanelController,
                              onSelect: (command) {
                                _chatInputKey.currentState?.insertCommand(
                                  command,
                                );
                                _chatInputKey.currentState?.focusInput();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedSession != null &&
                    homeState.permissionRequest != null)
                  SessionPermissionDock(request: homeState.permissionRequest!),
                if (homeState.showChatInput)
                  ChatInput(
                    key: _chatInputKey,
                    commandPanelController: _commandPanelController,
                  ),
              ],
            ),
            if (homeState.showQuestionOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(
                            context,
                          ).colorScheme.scrim.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (homeState.showQuestionOverlay &&
                homeState.questionRequest != null)
              QuestionOverlayCard(request: homeState.questionRequest!),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commandPanelAvailabilitySubscription.close();
    _commandPanelController.dispose();
    super.dispose();
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: tokens.mutedForeground),
        splashRadius: 20,
      ),
    );
  }
}
