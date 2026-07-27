// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomePageBootstrapController)
final homePageBootstrapControllerProvider =
    HomePageBootstrapControllerProvider._();

final class HomePageBootstrapControllerProvider
    extends $NotifierProvider<HomePageBootstrapController, String?> {
  HomePageBootstrapControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePageBootstrapControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePageBootstrapControllerHash();

  @$internal
  @override
  HomePageBootstrapController create() => HomePageBootstrapController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$homePageBootstrapControllerHash() =>
    r'a8f388c3e2c4ee4b16da4cf10719206ff72af69f';

abstract class _$HomePageBootstrapController extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(homePagePresentationState)
final homePagePresentationStateProvider = HomePagePresentationStateProvider._();

final class HomePagePresentationStateProvider
    extends
        $FunctionalProvider<
          HomePagePresentationState,
          HomePagePresentationState,
          HomePagePresentationState
        >
    with $Provider<HomePagePresentationState> {
  HomePagePresentationStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePagePresentationStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePagePresentationStateHash();

  @$internal
  @override
  $ProviderElement<HomePagePresentationState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomePagePresentationState create(Ref ref) {
    return homePagePresentationState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomePagePresentationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomePagePresentationState>(value),
    );
  }
}

String _$homePagePresentationStateHash() =>
    r'45910e1eda91de64b2a91f41b4c3a8c6b91cc8e1';
