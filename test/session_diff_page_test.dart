import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/pages/session_diff_page.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/vcs_api.dart';
import 'package:flycode/theme/app_theme.dart';

class _ModeHttpClient extends http.BaseClient {
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final mode = request.url.queryParameters['mode'];
    final file = mode == 'branch' ? 'lib/branch.dart' : 'lib/git.dart';
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          '[{"file":"$file","before":"","after":"content",'
          '"additions":1,"deletions":0,"status":"added"}]',
        ),
      ),
      200,
      request: request,
    );
  }
}

void main() {
  testWidgets('defaults to git diff and switches to branch diff', (
    tester,
  ) async {
    final rawClient = _ModeHttpClient();
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:4096',
      client: rawClient,
    );
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWith((ref) async => apiClient)],
    );
    addTearDown(() {
      container.dispose();
      apiClient.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SessionDiffPage(directory: '/tmp/project'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selector = tester.widget<SegmentedButton<VcsDiffMode>>(
      find.byType(SegmentedButton<VcsDiffMode>),
    );
    expect(selector.selected, {VcsDiffMode.git});
    expect(find.text('git.dart'), findsOneWidget);
    expect(rawClient.requests.single.url.queryParameters, {
      'mode': 'git',
      'directory': '/tmp/project',
    });

    await tester.tap(find.text('Branch'));
    await tester.pumpAndSettle();

    expect(find.text('branch.dart'), findsOneWidget);
    expect(rawClient.requests, hasLength(2));
    expect(rawClient.requests.last.url.queryParameters, {
      'mode': 'branch',
      'directory': '/tmp/project',
    });
  });
}
