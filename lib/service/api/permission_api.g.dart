// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(permissionApi)
final permissionApiProvider = PermissionApiProvider._();

final class PermissionApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<PermissionApi>,
          PermissionApi,
          FutureOr<PermissionApi>
        >
    with $FutureModifier<PermissionApi>, $FutureProvider<PermissionApi> {
  PermissionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionApiHash();

  @$internal
  @override
  $FutureProviderElement<PermissionApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PermissionApi> create(Ref ref) {
    return permissionApi(ref);
  }
}

String _$permissionApiHash() => r'b00d80d656cf9e4b408ceac39c612069ebb92041';
