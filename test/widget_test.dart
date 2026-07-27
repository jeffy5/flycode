import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/app.dart';
import 'package:flycode/providers/global_event_provider.dart';
import 'package:flycode/service/api/models/global_event.dart';

class _FakeGlobalEventListener extends GlobalEventListener {
  @override
  Stream<GlobalEvent> build() async* {}
}

void main() {
  testWidgets('App boots with ProviderScope', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalEventListenerProvider.overrideWith(
            _FakeGlobalEventListener.new,
          ),
        ],
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == '连接服务器' || widget.data == 'Connect Server'),
      ),
      findsWidgets,
    );
  });
}
