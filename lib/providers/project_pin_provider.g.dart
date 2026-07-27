// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_pin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectPinDatabaseHelper)
final projectPinDatabaseHelperProvider = ProjectPinDatabaseHelperProvider._();

final class ProjectPinDatabaseHelperProvider
    extends $FunctionalProvider<DatabaseHelper, DatabaseHelper, DatabaseHelper>
    with $Provider<DatabaseHelper> {
  ProjectPinDatabaseHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectPinDatabaseHelperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectPinDatabaseHelperHash();

  @$internal
  @override
  $ProviderElement<DatabaseHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseHelper create(Ref ref) {
    return projectPinDatabaseHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseHelper>(value),
    );
  }
}

String _$projectPinDatabaseHelperHash() =>
    r'ac49a7b78ee5152d55a401329ff0f645a802631d';

@ProviderFor(projectPinDao)
final projectPinDaoProvider = ProjectPinDaoProvider._();

final class ProjectPinDaoProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProjectPinDao>,
          ProjectPinDao,
          FutureOr<ProjectPinDao>
        >
    with $FutureModifier<ProjectPinDao>, $FutureProvider<ProjectPinDao> {
  ProjectPinDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectPinDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectPinDaoHash();

  @$internal
  @override
  $FutureProviderElement<ProjectPinDao> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProjectPinDao> create(Ref ref) {
    return projectPinDao(ref);
  }
}

String _$projectPinDaoHash() => r'8f1bf8ad2f5d0a78bcb34df262a6d06b515ea2d7';

@ProviderFor(ProjectPins)
final projectPinsProvider = ProjectPinsProvider._();

final class ProjectPinsProvider
    extends $AsyncNotifierProvider<ProjectPins, Map<String, int>> {
  ProjectPinsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectPinsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectPinsHash();

  @$internal
  @override
  ProjectPins create() => ProjectPins();
}

String _$projectPinsHash() => r'71440e4e5573623ed9aaabe8b7a8e52de66d6b97';

abstract class _$ProjectPins extends $AsyncNotifier<Map<String, int>> {
  FutureOr<Map<String, int>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, int>>, Map<String, int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, int>>, Map<String, int>>,
              AsyncValue<Map<String, int>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
