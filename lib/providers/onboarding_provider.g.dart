// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serverSetupCompleted)
final serverSetupCompletedProvider = ServerSetupCompletedProvider._();

final class ServerSetupCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  ServerSetupCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverSetupCompletedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverSetupCompletedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return serverSetupCompleted(ref);
  }
}

String _$serverSetupCompletedHash() =>
    r'9c8ee2e1067efa7aeb734bfc8f9fa2ce0962e907';

@ProviderFor(onboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

final class OnboardingControllerProvider
    extends
        $FunctionalProvider<
          OnboardingController,
          OnboardingController,
          OnboardingController
        >
    with $Provider<OnboardingController> {
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  $ProviderElement<OnboardingController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingController create(Ref ref) {
    return onboardingController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingController>(value),
    );
  }
}

String _$onboardingControllerHash() =>
    r'403d6f43c714442fe66c0922bd3047b943bdd34d';
