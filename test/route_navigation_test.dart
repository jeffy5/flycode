import 'package:flycode/models/typed_route_args.dart';
import 'package:flycode/route_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _buildHarness({required List<RouteBase> routes, required Widget home}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      ...routes,
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('pushSessionDiffById passes typed diff args', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => context.pushSessionDiffById('session-1'),
            child: const Text('open'),
          ),
        ),
        routes: [
          GoRoute(
            path: sessionDiffRoutePath,
            builder: (context, state) {
              final args = state.extra as SessionDiffRouteArgs;
              return Text(args.sessionID, textDirection: TextDirection.ltr);
            },
          ),
        ],
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('session-1'), findsOneWidget);
  });

  testWidgets('pushFileContentByPath passes typed file args', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => context.pushFileContentByPath('lib/router.dart'),
            child: const Text('open'),
          ),
        ),
        routes: [
          GoRoute(
            path: fileContentRoutePath,
            builder: (context, state) {
              final args = state.extra as FileContentRouteArgs;
              return Text(args.filePath, textDirection: TextDirection.ltr);
            },
          ),
        ],
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('lib/router.dart'), findsOneWidget);
  });

  testWidgets('pushSubSession passes typed sub-session args', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => context.pushSubSession(
              const SubSessionRouteArgs(sessionID: 'sub-1'),
            ),
            child: const Text('open'),
          ),
        ),
        routes: [
          GoRoute(
            path: subSessionRoutePath,
            builder: (context, state) {
              final args = state.extra as SubSessionRouteArgs;
              return Text(args.sessionID, textDirection: TextDirection.ltr);
            },
          ),
        ],
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('sub-1'), findsOneWidget);
  });

  testWidgets('pushSessionContextById passes typed session context args', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => context.pushSessionContextById('session-ctx-1'),
            child: const Text('open'),
          ),
        ),
        routes: [
          GoRoute(
            path: sessionContextRoutePath,
            builder: (context, state) {
              final args = state.extra as SessionContextRouteArgs;
              return Text(args.sessionID, textDirection: TextDirection.ltr);
            },
          ),
        ],
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('session-ctx-1'), findsOneWidget);
  });
}
