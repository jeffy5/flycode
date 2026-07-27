import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/providers/current_directory_provider.dart';
import 'package:flycode/providers/question_provider.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/models/question.dart';
import 'package:flycode/service/api/question_api.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/question/question_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeQuestionApi extends QuestionApi {
  _FakeQuestionApi(this._requests)
    : super(ApiClient(baseUrl: 'http://localhost'));

  final List<QuestionRequest> _requests;
  final List<String> rejectedRequestIds = <String>[];
  final Map<String, List<List<String>>> replies =
      <String, List<List<String>>>{};

  @override
  Future<List<QuestionRequest>> getQuestions({String? directory}) async =>
      List<QuestionRequest>.from(_requests);

  @override
  Future<bool> replyQuestion(
    String requestID, {
    required List<List<String>> answers,
    String? directory,
  }) async {
    replies[requestID] = answers;
    return true;
  }

  @override
  Future<bool> rejectQuestion(String requestID, {String? directory}) async {
    rejectedRequestIds.add(requestID);
    return true;
  }
}

class _QuestionOverlayCoordinator extends ConsumerWidget {
  const _QuestionOverlayCoordinator({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(pendingQuestionsProvider).asData?.value;
    final request = questions
        ?.where((question) => question.sessionID == sessionId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Question Host'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF7F7FB))),
          if (request != null) QuestionOverlayCard(request: request),
        ],
      ),
    );
  }
}

QuestionRequest _buildRequest({
  String id = 'question-1',
  String sessionId = 'session-1',
  int optionCount = 3,
}) {
  return QuestionRequest(
    id: id,
    sessionID: sessionId,
    questions: [
      QuestionInfo(
        header: 'Workflow confirmation',
        question:
            'Please confirm how you want to continue with this task before the'
            ' agent proceeds with execution.',
        multiple: optionCount > 1,
        custom: true,
        options: List<QuestionOption>.generate(
          optionCount,
          (index) => QuestionOption(
            label: 'Option ${index + 1}',
            description:
                'Detailed explanation for option ${index + 1} so the overlay'
                ' has enough content to scroll when the keyboard is open.',
          ),
        ),
      ),
    ],
  );
}

Widget _buildCoordinatorHarness(
  ProviderContainer container, {
  required String sessionId,
  NavigatorObserver? observer,
  bool canPop = false,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: canPop
          ? Navigator(
              key: navigatorKey,
              observers: observer == null
                  ? const <NavigatorObserver>[]
                  : <NavigatorObserver>[observer],
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: SizedBox.expand()),
                settings: const RouteSettings(name: 'root'),
              ),
              onGenerateInitialRoutes: (context, initialRoute) => [
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: SizedBox.expand()),
                  settings: const RouteSettings(name: 'root'),
                ),
                MaterialPageRoute<void>(
                  builder: (_) =>
                      _QuestionOverlayCoordinator(sessionId: sessionId),
                  settings: const RouteSettings(name: 'question'),
                ),
              ],
            )
          : _QuestionOverlayCoordinator(sessionId: sessionId),
    ),
  );
}

Widget _buildOverlayHarness({
  required ProviderContainer container,
  required QuestionRequest request,
  required double bottomInset,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: const EdgeInsets.only(top: 44),
          viewInsets: EdgeInsets.only(bottom: bottomInset),
        ),
        child: Scaffold(
          body: Stack(children: [QuestionOverlayCard(request: request)]),
        ),
      ),
    ),
  );
}

class _RecordingObserver extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops += 1;
    super.didPop(route, previousRoute);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('overlay appears once and disappears when question is removed', (
    tester,
  ) async {
    final question = _buildRequest();
    final api = _FakeQuestionApi([question]);
    final container = ProviderContainer(
      overrides: [
        currentDirectoryProvider.overrideWithValue('/tmp/project'),
        questionApiProvider.overrideWith((ref) async => api),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildCoordinatorHarness(container, sessionId: question.sessionID),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('question_overlay.surface')), findsOneWidget);

    await tester.pump();
    expect(find.byKey(const Key('question_overlay.surface')), findsOneWidget);

    container
        .read(pendingQuestionsProvider.notifier)
        .removeQuestion(question.id);
    await tester.pump();

    expect(find.byKey(const Key('question_overlay.surface')), findsNothing);
  });

  testWidgets('long question stays scrollable with keyboard open', (
    tester,
  ) async {
    final question = _buildRequest(optionCount: 18);
    final api = _FakeQuestionApi([question]);
    final container = ProviderContainer(
      overrides: [
        currentDirectoryProvider.overrideWithValue('/tmp/project'),
        questionApiProvider.overrideWith((ref) async => api),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildOverlayHarness(
        container: container,
        request: question,
        bottomInset: 280,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('question_overlay.surface')), findsOneWidget);
    expect(find.text('提交'), findsOneWidget);
    expect(find.text('忽略'), findsOneWidget);

    final surfaceRect = tester.getRect(
      find.byKey(const Key('question_overlay.surface')),
    );
    final actionsRect = tester.getRect(
      find.byKey(const Key('question_overlay.actions')),
    );
    expect(actionsRect.bottom, lessThanOrEqualTo(surfaceRect.bottom));

    final scrollable = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .firstWhere((state) => state.position.maxScrollExtent > 0);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    final customInputRect = tester.getRect(find.byType(TextField).last);
    expect(customInputRect.bottom, lessThan(actionsRect.top));
  });

  testWidgets('ignore rejects the request and closes the overlay', (
    tester,
  ) async {
    final question = _buildRequest();
    final api = _FakeQuestionApi([question]);
    final container = ProviderContainer(
      overrides: [
        currentDirectoryProvider.overrideWithValue('/tmp/project'),
        questionApiProvider.overrideWith((ref) async => api),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildCoordinatorHarness(container, sessionId: question.sessionID),
    );
    await tester.pumpAndSettle();

    final ignoreButton = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const Key('question_overlay.actions')),
        matching: find.byType(TextButton),
      ),
    );
    ignoreButton.onPressed?.call();
    await tester.pump();
    await tester.pump();

    expect(api.rejectedRequestIds, [question.id]);
    expect(find.byKey(const Key('question_overlay.surface')), findsNothing);
  });

  testWidgets('question overlay does not consume navigator back', (
    tester,
  ) async {
    final question = _buildRequest();
    final api = _FakeQuestionApi([question]);
    final container = ProviderContainer(
      overrides: [
        currentDirectoryProvider.overrideWithValue('/tmp/project'),
        questionApiProvider.overrideWith((ref) async => api),
      ],
    );
    final observer = _RecordingObserver();
    final navigatorKey = GlobalKey<NavigatorState>();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildCoordinatorHarness(
        container,
        sessionId: question.sessionID,
        observer: observer,
        canPop: true,
        navigatorKey: navigatorKey,
      ),
    );
    await tester.pumpAndSettle();

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(observer.pops, 1);
    expect(find.byKey(const Key('question_overlay.surface')), findsNothing);
  });
}
