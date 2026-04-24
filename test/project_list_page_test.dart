import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/models/server_config.dart';
import 'package:flycode/pages/project_list_page.dart';
import 'package:flycode/providers/project_pin_provider.dart';
import 'package:flycode/providers/server_config_provider.dart';
import 'package:flycode/service/api/models/project.dart';
import 'package:flycode/service/api/project_api.dart';
import 'package:flycode/theme/app_theme.dart';

class _FakeProjects extends Projects {
  @override
  Future<List<Project>> build() async => [
    Project(
      id: '1',
      worktree: '/Users/jeffrey/work/flycode',
      name: 'FlyCode Mobile',
      time: ProjectTime(created: 1, updated: 200),
      sandboxes: const [],
    ),
    Project(
      id: '2',
      worktree: '/Users/jeffrey/work/docs-platform',
      name: 'Docs Platform',
      time: ProjectTime(created: 1, updated: 100),
      sandboxes: const [],
    ),
  ];
}

class _FakeProjectPins extends ProjectPins {
  @override
  Future<Map<String, int>> build() async => const {};
}

Widget _buildPage(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const ProjectListPage(),
    ),
  );
}

class _FakeServerConfigNotifier extends ServerConfigNotifier {
  @override
  Future<ServerConfig> build() async => ServerConfig.defaultValue();
}

void main() {
  testWidgets('project list supports fuzzy search by name and path', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        projectsProvider.overrideWith(_FakeProjects.new),
        projectPinsProvider.overrideWith(_FakeProjectPins.new),
        serverConfigProvider.overrideWith(_FakeServerConfigNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildPage(container));
    await tester.pumpAndSettle();

    expect(find.text('FlyCode Mobile'), findsOneWidget);
    expect(find.text('Docs Platform'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'fcm');
    await tester.pump();

    expect(find.text('FlyCode Mobile'), findsOneWidget);
    expect(find.text('Docs Platform'), findsNothing);

    await tester.enterText(find.byType(TextField), 'docsplf');
    await tester.pump();

    expect(find.text('Docs Platform'), findsOneWidget);
    expect(find.text('FlyCode Mobile'), findsNothing);
  });
}
