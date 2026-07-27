// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globalEventDispatcher)
final globalEventDispatcherProvider = GlobalEventDispatcherProvider._();

final class GlobalEventDispatcherProvider
    extends
        $FunctionalProvider<
          GlobalEventDispatcher,
          GlobalEventDispatcher,
          GlobalEventDispatcher
        >
    with $Provider<GlobalEventDispatcher> {
  GlobalEventDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalEventDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalEventDispatcherHash();

  @$internal
  @override
  $ProviderElement<GlobalEventDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalEventDispatcher create(Ref ref) {
    return globalEventDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalEventDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalEventDispatcher>(value),
    );
  }
}

String _$globalEventDispatcherHash() =>
    r'68037b51a714e96d6408a92d7fa57fc270ca4867';
