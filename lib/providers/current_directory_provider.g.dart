// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_directory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentDirectory)
final currentDirectoryProvider = CurrentDirectoryProvider._();

final class CurrentDirectoryProvider
    extends $NotifierProvider<CurrentDirectory, String?> {
  CurrentDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDirectoryHash();

  @$internal
  @override
  CurrentDirectory create() => CurrentDirectory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentDirectoryHash() => r'bb01acd2c316429cfc028f41814d0d485b8d6212';

abstract class _$CurrentDirectory extends $Notifier<String?> {
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
