// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globalApi)
final globalApiProvider = GlobalApiProvider._();

final class GlobalApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<GlobalApi>,
          GlobalApi,
          FutureOr<GlobalApi>
        >
    with $FutureModifier<GlobalApi>, $FutureProvider<GlobalApi> {
  GlobalApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalApiHash();

  @$internal
  @override
  $FutureProviderElement<GlobalApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GlobalApi> create(Ref ref) {
    return globalApi(ref);
  }
}

String _$globalApiHash() => r'f01ce5f2e197fda4736282ca300a5216df0f00f6';
