import 'package:flycode/pages/about_page.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AboutPage renders key content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AboutPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('关于'), findsOneWidget);
    expect(find.text('FlyCode'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('jeffy5/flycode'), findsOneWidget);
    expect(find.text('当前版本'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.text('让 coding 随时发生。你可以在手机上继续项目、衔接会话与灵感。'), findsOneWidget);
  });
}
