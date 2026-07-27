import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import 'main_tab_page.dart';
import 'server_config_page.dart';

class AppEntryPage extends ConsumerWidget {
  const AppEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(serverSetupCompletedProvider);

    return completedAsync.when(
      data: (completed) {
        if (completed) {
          return const MainTabPage();
        }
        return const ServerConfigPage(onboardingMode: true);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) {
        return const ServerConfigPage(onboardingMode: true);
      },
    );
  }
}
