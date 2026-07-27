import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/pages/sub_session_page.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/models/message.dart';
import 'package:flycode/service/api/session_api.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThrowingSessionApi extends SessionApi {
  _ThrowingSessionApi() : super(ApiClient(baseUrl: 'http://localhost'));

  @override
  Future<List<MessageWithParts>> getSessionMessages(
    String id, {
    String? directory,
    int? limit,
  }) async {
    throw StateError('backend exploded');
  }
}

Widget _buildHarness(Widget child) {
  final container = ProviderContainer(
    overrides: [
      sessionApiProvider.overrideWith((ref) async => _ThrowingSessionApi()),
    ],
  );

  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('MessageList shows friendly error without internal details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(const Scaffold(body: MessageList(sessionID: 'session-1'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('消息加载失败，请稍后重试'), findsOneWidget);
    expect(find.textContaining('backend exploded'), findsNothing);
    expect(find.textContaining('Stack trace'), findsNothing);
  });

  testWidgets('SubSessionPage shows friendly error without internal details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(const SubSessionPage(sessionID: 'session-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('消息加载失败，请稍后重试'), findsOneWidget);
    expect(find.textContaining('backend exploded'), findsNothing);
    expect(find.textContaining('Stack trace'), findsNothing);
  });
}
