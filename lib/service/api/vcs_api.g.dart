// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vcs_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(vcsApi)
final vcsApiProvider = VcsApiProvider._();

final class VcsApiProvider
    extends $FunctionalProvider<AsyncValue<VcsApi>, VcsApi, FutureOr<VcsApi>>
    with $FutureModifier<VcsApi>, $FutureProvider<VcsApi> {
  VcsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vcsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vcsApiHash();

  @$internal
  @override
  $FutureProviderElement<VcsApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<VcsApi> create(Ref ref) {
    return vcsApi(ref);
  }
}

String _$vcsApiHash() => r'e8229a6333c88377c2ae8b2ca2165488ad2c4d3f';

@ProviderFor(vcsDiff)
final vcsDiffProvider = VcsDiffFamily._();

final class VcsDiffProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileDiff>>,
          List<FileDiff>,
          FutureOr<List<FileDiff>>
        >
    with $FutureModifier<List<FileDiff>>, $FutureProvider<List<FileDiff>> {
  VcsDiffProvider._({
    required VcsDiffFamily super.from,
    required (VcsDiffMode, String) super.argument,
  }) : super(
         retry: null,
         name: r'vcsDiffProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vcsDiffHash();

  @override
  String toString() {
    return r'vcsDiffProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<FileDiff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FileDiff>> create(Ref ref) {
    final argument = this.argument as (VcsDiffMode, String);
    return vcsDiff(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is VcsDiffProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vcsDiffHash() => r'2d9b4fe9879315e9fef286cbf0914029518be417';

final class VcsDiffFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<FileDiff>>,
          (VcsDiffMode, String)
        > {
  VcsDiffFamily._()
    : super(
        retry: null,
        name: r'vcsDiffProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VcsDiffProvider call(VcsDiffMode mode, String directory) =>
      VcsDiffProvider._(argument: (mode, directory), from: this);

  @override
  String toString() => r'vcsDiffProvider';
}
