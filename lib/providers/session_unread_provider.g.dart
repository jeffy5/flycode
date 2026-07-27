// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_unread_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionUnreadNotifier)
final sessionUnreadProvider = SessionUnreadNotifierProvider._();

final class SessionUnreadNotifierProvider
    extends $NotifierProvider<SessionUnreadNotifier, SessionUnreadState> {
  SessionUnreadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionUnreadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionUnreadNotifierHash();

  @$internal
  @override
  SessionUnreadNotifier create() => SessionUnreadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionUnreadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionUnreadState>(value),
    );
  }
}

String _$sessionUnreadNotifierHash() =>
    r'd7ab238cd9a63c2cf7769dbd7832f76d567bfce1';

abstract class _$SessionUnreadNotifier extends $Notifier<SessionUnreadState> {
  SessionUnreadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SessionUnreadState, SessionUnreadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionUnreadState, SessionUnreadState>,
              SessionUnreadState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(sessionUnseenCount)
final sessionUnseenCountProvider = SessionUnseenCountFamily._();

final class SessionUnseenCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  SessionUnseenCountProvider._({
    required SessionUnseenCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionUnseenCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionUnseenCountHash();

  @override
  String toString() {
    return r'sessionUnseenCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as String;
    return sessionUnseenCount(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionUnseenCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionUnseenCountHash() =>
    r'a2a2ec4a467447e62d3648b3c65aee554aa86a10';

final class SessionUnseenCountFamily extends $Family
    with $FunctionalFamilyOverride<int, String> {
  SessionUnseenCountFamily._()
    : super(
        retry: null,
        name: r'sessionUnseenCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionUnseenCountProvider call(String sessionID) =>
      SessionUnseenCountProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'sessionUnseenCountProvider';
}

@ProviderFor(sessionHasUnreadError)
final sessionHasUnreadErrorProvider = SessionHasUnreadErrorFamily._();

final class SessionHasUnreadErrorProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  SessionHasUnreadErrorProvider._({
    required SessionHasUnreadErrorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionHasUnreadErrorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionHasUnreadErrorHash();

  @override
  String toString() {
    return r'sessionHasUnreadErrorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return sessionHasUnreadError(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionHasUnreadErrorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionHasUnreadErrorHash() =>
    r'7517f0a44411b49e94095aff0a6f911bed73303a';

final class SessionHasUnreadErrorFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  SessionHasUnreadErrorFamily._()
    : super(
        retry: null,
        name: r'sessionHasUnreadErrorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionHasUnreadErrorProvider call(String sessionID) =>
      SessionHasUnreadErrorProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'sessionHasUnreadErrorProvider';
}
