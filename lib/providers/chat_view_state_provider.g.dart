// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_view_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatViewStateNotifier)
final chatViewStateProvider = ChatViewStateNotifierProvider._();

final class ChatViewStateNotifierProvider
    extends $NotifierProvider<ChatViewStateNotifier, ChatViewState> {
  ChatViewStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatViewStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatViewStateNotifierHash();

  @$internal
  @override
  ChatViewStateNotifier create() => ChatViewStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatViewState>(value),
    );
  }
}

String _$chatViewStateNotifierHash() =>
    r'032ee5a81854ed0e6283394a0b86db3711d4b1d8';

abstract class _$ChatViewStateNotifier extends $Notifier<ChatViewState> {
  ChatViewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatViewState, ChatViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatViewState, ChatViewState>,
              ChatViewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
