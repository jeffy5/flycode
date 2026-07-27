// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_preferences_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localPreferencesRepository)
final localPreferencesRepositoryProvider =
    LocalPreferencesRepositoryProvider._();

final class LocalPreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          LocalPreferencesRepository,
          LocalPreferencesRepository,
          LocalPreferencesRepository
        >
    with $Provider<LocalPreferencesRepository> {
  LocalPreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localPreferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localPreferencesRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalPreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalPreferencesRepository create(Ref ref) {
    return localPreferencesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalPreferencesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalPreferencesRepository>(value),
    );
  }
}

String _$localPreferencesRepositoryHash() =>
    r'642d9d935e8ad7e0e944591fd75469ac58215396';
