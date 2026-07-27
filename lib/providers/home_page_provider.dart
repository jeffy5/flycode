import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/chat_route_args.dart';
import '../service/api/models/permission.dart';
import '../service/api/models/question.dart';
import '../service/api/models/session.dart';
import '../service/api/session_api.dart';
import 'chat_view_state_provider.dart';
import 'current_directory_provider.dart';
import 'permission_provider.dart';
import 'question_provider.dart';

part 'home_page_provider.g.dart';

enum HomePageBodyMode {
  messageList,
  newSessionWelcome,
  sessionSelection,
  loading,
  error,
}

class HomePagePresentationState {
  const HomePagePresentationState({
    required this.sessionId,
    required this.isPending,
    required this.selectedSession,
    required this.permissionRequest,
    required this.questionRequest,
    required this.bodyMode,
    required this.hasAnySessions,
    required this.showChatInput,
    required this.showQuestionOverlay,
    required this.canShowCommandPanel,
    this.loadError,
  });

  final String? sessionId;
  final bool isPending;
  final Session? selectedSession;
  final PermissionRequest? permissionRequest;
  final QuestionRequest? questionRequest;
  final HomePageBodyMode bodyMode;
  final bool hasAnySessions;
  final bool showChatInput;
  final bool showQuestionOverlay;
  final bool canShowCommandPanel;
  final Object? loadError;
}

HomePagePresentationState buildHomePagePresentationState({
  required AsyncValue<List<Session>> sessionsAsync,
  required ChatViewState chatState,
  required PermissionRequest? permissionRequest,
  required QuestionRequest? questionRequest,
}) {
  final sessionId = chatState.sessionId;
  final isPending = chatState.isPending;
  final sessions = sessionsAsync.asData?.value;
  final selectedSession = findSessionById(sessions, sessionId);
  final hasAnySessions = sessions?.isNotEmpty ?? false;
  final hasPermissionBlock = permissionRequest != null;
  final hasQuestion = questionRequest != null;
  final hasActiveOrPendingSession = sessionId != null || isPending;
  final showChatInput =
      hasActiveOrPendingSession && !hasPermissionBlock && !hasQuestion;
  final showQuestionOverlay =
      hasActiveOrPendingSession && !hasPermissionBlock && hasQuestion;

  final bodyMode = switch (sessionsAsync) {
    AsyncError() => HomePageBodyMode.error,
    AsyncLoading() when sessionId == null && !isPending =>
      HomePageBodyMode.loading,
    _ when selectedSession != null => HomePageBodyMode.messageList,
    _ when isPending => HomePageBodyMode.newSessionWelcome,
    _ when sessionId != null => HomePageBodyMode.loading,
    _ => HomePageBodyMode.sessionSelection,
  };

  return HomePagePresentationState(
    sessionId: sessionId,
    isPending: isPending,
    selectedSession: selectedSession,
    permissionRequest: permissionRequest,
    questionRequest: questionRequest,
    bodyMode: bodyMode,
    hasAnySessions: hasAnySessions,
    showChatInput: showChatInput,
    showQuestionOverlay: showQuestionOverlay,
    canShowCommandPanel: showChatInput,
    loadError: sessionsAsync.asError?.error,
  );
}

Session? findSessionById(List<Session>? sessions, String? sessionId) {
  if (sessions == null || sessionId == null) return null;
  for (final session in sessions) {
    if (session.id == sessionId) {
      return session;
    }
  }
  return null;
}

Session? selectBootstrapSession(
  List<Session> sessions, {
  String? initialSessionId,
}) {
  if (sessions.isEmpty) return null;

  final initialMatch = findSessionById(sessions, initialSessionId);
  if (initialMatch != null) {
    return initialMatch;
  }

  final sortedSessions = List<Session>.from(sessions)
    ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
  return sortedSessions.firstOrNull;
}

@Riverpod(keepAlive: true)
class HomePageBootstrapController extends _$HomePageBootstrapController {
  int _bootstrapGeneration = 0;

  @override
  String? build() => null;

  Future<void> bootstrap(ChatRouteArgs? args) async {
    final routeKey = _routeKey(args);
    if (state == routeKey) return;

    final generation = ++_bootstrapGeneration;
    state = routeKey;

    final directory = args?.directory.trim();
    if (directory == null || directory.isEmpty) {
      return;
    }

    ref.read(currentDirectoryProvider.notifier).set(directory);

    final viewState = ref.read(chatViewStateProvider.notifier);
    if (args?.startNew == true) {
      viewState.startNew();
      return;
    }

    viewState.clear();

    try {
      final sessions = await ref.refresh(sessionsProvider.future);
      if (!_isLatestBootstrap(generation)) return;

      final bootstrapSession = selectBootstrapSession(
        sessions,
        initialSessionId: args?.initialSessionId,
      );
      if (bootstrapSession != null) {
        viewState.selectSessionId(bootstrapSession.id);
        return;
      }
      viewState.startNew();
    } catch (_) {
      if (!_isLatestBootstrap(generation)) return;
      viewState.startNew();
    }
  }

  void reset() {
    _bootstrapGeneration++;
    state = null;
  }

  bool _isLatestBootstrap(int generation) => generation == _bootstrapGeneration;

  String _routeKey(ChatRouteArgs? args) {
    final directory = args?.directory.trim() ?? '';
    final sessionId = args?.initialSessionId ?? '';
    final startNew = args?.startNew == true ? '1' : '0';
    return '$directory|$sessionId|$startNew';
  }
}

@riverpod
HomePagePresentationState homePagePresentationState(Ref ref) {
  final sessionsAsync = ref.watch(sessionsProvider);
  final chatState = ref.watch(chatViewStateProvider);
  final sessionId = chatState.sessionId;
  final permissionRequest = sessionId == null
      ? null
      : ref.watch(currentSessionPermissionRequestProvider(sessionId));
  final pendingQuestions = ref.watch(pendingQuestionsProvider).asData?.value;
  final questionRequest = sessionId == null
      ? null
      : pendingQuestions?.where((q) => q.sessionID == sessionId).firstOrNull;

  return buildHomePagePresentationState(
    sessionsAsync: sessionsAsync,
    chatState: chatState,
    permissionRequest: permissionRequest,
    questionRequest: questionRequest,
  );
}
