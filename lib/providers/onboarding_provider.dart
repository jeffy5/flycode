import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'local_preferences_repository.dart';

part 'onboarding_provider.g.dart';

@riverpod
Future<bool> serverSetupCompleted(Ref ref) async {
  final repository = ref.watch(localPreferencesRepositoryProvider);
  return repository.loadServerSetupCompleted();
}

@riverpod
OnboardingController onboardingController(Ref ref) {
  return OnboardingController(ref);
}

class OnboardingController {
  OnboardingController(this._ref);

  final Ref _ref;

  Future<void> markServerSetupCompleted() async {
    final repository = _ref.read(localPreferencesRepositoryProvider);
    await repository.saveServerSetupCompleted(true);
    _ref.invalidate(serverSetupCompletedProvider);
  }
}
