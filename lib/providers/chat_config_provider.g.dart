// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatConfigNotifier)
final chatConfigProvider = ChatConfigNotifierProvider._();

final class ChatConfigNotifierProvider
    extends $NotifierProvider<ChatConfigNotifier, ChatConfig> {
  ChatConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatConfigNotifierHash();

  @$internal
  @override
  ChatConfigNotifier create() => ChatConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatConfig>(value),
    );
  }
}

String _$chatConfigNotifierHash() =>
    r'247bf5e11ec18950c5054067f688629c9dbe5ed1';

abstract class _$ChatConfigNotifier extends $Notifier<ChatConfig> {
  ChatConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatConfig, ChatConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatConfig, ChatConfig>,
              ChatConfig,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
