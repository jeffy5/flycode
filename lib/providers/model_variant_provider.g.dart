// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_variant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ModelVariant)
final modelVariantProvider = ModelVariantProvider._();

final class ModelVariantProvider
    extends $NotifierProvider<ModelVariant, ModelVariantState> {
  ModelVariantProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelVariantProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelVariantHash();

  @$internal
  @override
  ModelVariant create() => ModelVariant();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelVariantState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelVariantState>(value),
    );
  }
}

String _$modelVariantHash() => r'a68d73730212de38e05e5b8e2b786a231162117d';

abstract class _$ModelVariant extends $Notifier<ModelVariantState> {
  ModelVariantState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ModelVariantState, ModelVariantState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ModelVariantState, ModelVariantState>,
              ModelVariantState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
