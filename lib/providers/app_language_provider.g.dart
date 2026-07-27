// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_language_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppLanguageNotifier)
final appLanguageProvider = AppLanguageNotifierProvider._();

final class AppLanguageNotifierProvider
    extends $NotifierProvider<AppLanguageNotifier, app_language.AppLanguage> {
  AppLanguageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLanguageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLanguageNotifierHash();

  @$internal
  @override
  AppLanguageNotifier create() => AppLanguageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(app_language.AppLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<app_language.AppLanguage>(value),
    );
  }
}

String _$appLanguageNotifierHash() =>
    r'bbd111e1d2c40e33d93604d4ba0b3fcf8ca79460';

abstract class _$AppLanguageNotifier
    extends $Notifier<app_language.AppLanguage> {
  app_language.AppLanguage build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<app_language.AppLanguage, app_language.AppLanguage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<app_language.AppLanguage, app_language.AppLanguage>,
              app_language.AppLanguage,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
