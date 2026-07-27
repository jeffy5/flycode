// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectApi)
final projectApiProvider = ProjectApiProvider._();

final class ProjectApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProjectApi>,
          ProjectApi,
          FutureOr<ProjectApi>
        >
    with $FutureModifier<ProjectApi>, $FutureProvider<ProjectApi> {
  ProjectApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectApiHash();

  @$internal
  @override
  $FutureProviderElement<ProjectApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ProjectApi> create(Ref ref) {
    return projectApi(ref);
  }
}

String _$projectApiHash() => r'aa718dc825630bb1802dff1ca98b9d006ca7901b';

@ProviderFor(Projects)
final projectsProvider = ProjectsProvider._();

final class ProjectsProvider
    extends $AsyncNotifierProvider<Projects, List<Project>> {
  ProjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectsHash();

  @$internal
  @override
  Projects create() => Projects();
}

String _$projectsHash() => r'059893d4f6080553e95c7164c68252a8d45c0225';

abstract class _$Projects extends $AsyncNotifier<List<Project>> {
  FutureOr<List<Project>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Project>>, List<Project>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Project>>, List<Project>>,
              AsyncValue<List<Project>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
