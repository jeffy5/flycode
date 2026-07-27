// ignore_for_file: type=lint

import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/models/global_event.dart';
import 'package:flycode/service/api/session_api.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/session/todo_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionApi extends SessionApi {
  _FakeSessionApi(this.todos) : super(ApiClient(baseUrl: 'http://localhost'));

  final List<Todo> todos;

  @override
  Future<List<Todo>> getSessionTodos(String id, {String? directory}) async =>
      todos;
}

Widget _buildHarness(List<Todo> todos) {
  return ProviderScope(
    overrides: [
      sessionApiProvider.overrideWith((ref) async => _FakeSessionApi(todos)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: TodoListWidget(sessionID: 'session-1')),
    ),
  );
}

Todo _todo({
  required String content,
  required String status,
  String priority = 'low',
}) {
  return Todo(content: content, status: status, priority: priority);
}

void main() {
  testWidgets('expanded state keeps backend todo order', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness([
        _todo(content: '完成但保留原位', status: 'completed'),
        _todo(content: '当前进行中', status: 'in_progress'),
        _todo(content: '后续待处理', status: 'pending'),
      ]),
    );
    await tester.pumpAndSettle();

    final completedY = tester.getTopLeft(find.text('完成但保留原位')).dy;
    final inProgressY = tester.getTopLeft(find.text('当前进行中')).dy;
    final pendingY = tester.getTopLeft(find.text('后续待处理')).dy;

    expect(completedY, lessThan(inProgressY));
    expect(inProgressY, lessThan(pendingY));
  });

  testWidgets('collapsed state shows only first in progress todo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness([
        _todo(content: '第一个进行中', status: 'in_progress'),
        _todo(content: '第二个进行中', status: 'in_progress'),
        _todo(content: '排队任务', status: 'pending'),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 任务规划'));
    await tester.pumpAndSettle();

    expect(find.text('第一个进行中'), findsOneWidget);
    expect(find.text('第二个进行中'), findsNothing);
    expect(find.text('排队任务'), findsNothing);
  });

  testWidgets('collapsed state without in progress todo keeps header only', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness([
        _todo(content: '待处理任务', status: 'pending'),
        _todo(content: '已完成任务', status: 'completed'),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 任务规划'));
    await tester.pumpAndSettle();

    expect(find.text('AI 任务规划'), findsOneWidget);
    expect(find.text('待处理任务'), findsNothing);
    expect(find.text('已完成任务'), findsNothing);
  });

  testWidgets('all completed todos hide the entire widget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness([
        _todo(content: '已完成 A', status: 'completed'),
        _todo(content: '已完成 B', status: 'completed'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TodoListWidget), findsOneWidget);
    expect(find.text('AI 任务规划'), findsNothing);
    expect(find.text('已完成 A'), findsNothing);
    expect(find.text('已完成 B'), findsNothing);
  });

  testWidgets('completed todo keeps completion styling in place', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness([
        _todo(content: '已完成但不挪位', status: 'completed'),
        _todo(content: '正在处理', status: 'in_progress'),
      ]),
    );
    await tester.pumpAndSettle();

    final completedText = tester.widget<Text>(find.text('已完成但不挪位'));
    final completedY = tester.getTopLeft(find.text('已完成但不挪位')).dy;
    final activeY = tester.getTopLeft(find.text('正在处理')).dy;

    expect(completedText.style?.decoration, TextDecoration.lineThrough);
    expect(completedY, lessThan(activeY));
  });
}
