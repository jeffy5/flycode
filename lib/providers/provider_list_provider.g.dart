// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProviderList)
final providerListProvider = ProviderListProvider._();

final class ProviderListProvider
    extends $AsyncNotifierProvider<ProviderList, ProviderListResponse> {
  ProviderListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerListHash();

  @$internal
  @override
  ProviderList create() => ProviderList();
}

String _$providerListHash() => r'b716f614954154f388d1d11403693319b1fcbd7c';

abstract class _$ProviderList extends $AsyncNotifier<ProviderListResponse> {
  FutureOr<ProviderListResponse> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ProviderListResponse>, ProviderListResponse>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ProviderListResponse>,
                ProviderListResponse
              >,
              AsyncValue<ProviderListResponse>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
