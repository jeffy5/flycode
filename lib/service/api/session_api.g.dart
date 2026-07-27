// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionApi)
final sessionApiProvider = SessionApiProvider._();

final class SessionApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionApi>,
          SessionApi,
          FutureOr<SessionApi>
        >
    with $FutureModifier<SessionApi>, $FutureProvider<SessionApi> {
  SessionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionApiHash();

  @$internal
  @override
  $FutureProviderElement<SessionApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SessionApi> create(Ref ref) {
    return sessionApi(ref);
  }
}

String _$sessionApiHash() => r'c8e5e575ab5bb6c195fd1862c14d7767f9325e29';

@ProviderFor(sessions)
final sessionsProvider = SessionsProvider._();

final class SessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Session>>,
          List<Session>,
          FutureOr<List<Session>>
        >
    with $FutureModifier<List<Session>>, $FutureProvider<List<Session>> {
  SessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Session>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Session>> create(Ref ref) {
    return sessions(ref);
  }
}

String _$sessionsHash() => r'84822902c9a5ac7a14b2cf58ddc31488e3bfcdcc';
