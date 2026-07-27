// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionMessagesNotifier)
final sessionMessagesProvider = SessionMessagesNotifierFamily._();

final class SessionMessagesNotifierProvider
    extends
        $AsyncNotifierProvider<
          SessionMessagesNotifier,
          List<MessageWithParts>
        > {
  SessionMessagesNotifierProvider._({
    required SessionMessagesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionMessagesNotifierHash();

  @override
  String toString() {
    return r'sessionMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionMessagesNotifier create() => SessionMessagesNotifier();

  @override
  bool operator ==(Object other) {
    return other is SessionMessagesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionMessagesNotifierHash() =>
    r'1e3a0c7c8f9a1b9fb15312c5054cfd6f60eea068';

final class SessionMessagesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionMessagesNotifier,
          AsyncValue<List<MessageWithParts>>,
          List<MessageWithParts>,
          FutureOr<List<MessageWithParts>>,
          String
        > {
  SessionMessagesNotifierFamily._()
    : super(
        retry: null,
        name: r'sessionMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionMessagesNotifierProvider call(String sessionID) =>
      SessionMessagesNotifierProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'sessionMessagesProvider';
}

abstract class _$SessionMessagesNotifier
    extends $AsyncNotifier<List<MessageWithParts>> {
  late final _$args = ref.$arg as String;
  String get sessionID => _$args;

  FutureOr<List<MessageWithParts>> build(String sessionID);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MessageWithParts>>, List<MessageWithParts>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MessageWithParts>>,
                List<MessageWithParts>
              >,
              AsyncValue<List<MessageWithParts>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(sessionDiff)
final sessionDiffProvider = SessionDiffFamily._();

final class SessionDiffProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileDiff>>,
          List<FileDiff>,
          FutureOr<List<FileDiff>>
        >
    with $FutureModifier<List<FileDiff>>, $FutureProvider<List<FileDiff>> {
  SessionDiffProvider._({
    required SessionDiffFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionDiffProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionDiffHash();

  @override
  String toString() {
    return r'sessionDiffProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FileDiff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FileDiff>> create(Ref ref) {
    final argument = this.argument as String;
    return sessionDiff(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionDiffProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionDiffHash() => r'dc5fdb3610ea7e29f9a3739f3f02e005dc704b5c';

final class SessionDiffFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FileDiff>>, String> {
  SessionDiffFamily._()
    : super(
        retry: null,
        name: r'sessionDiffProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionDiffProvider call(String sessionID) =>
      SessionDiffProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'sessionDiffProvider';
}

/// 子 Session 消息列表（只读，支持 SSE 实时更新）

@ProviderFor(SubSessionMessagesNotifier)
final subSessionMessagesProvider = SubSessionMessagesNotifierFamily._();

/// 子 Session 消息列表（只读，支持 SSE 实时更新）
final class SubSessionMessagesNotifierProvider
    extends
        $AsyncNotifierProvider<
          SubSessionMessagesNotifier,
          List<MessageWithParts>
        > {
  /// 子 Session 消息列表（只读，支持 SSE 实时更新）
  SubSessionMessagesNotifierProvider._({
    required SubSessionMessagesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'subSessionMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subSessionMessagesNotifierHash();

  @override
  String toString() {
    return r'subSessionMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SubSessionMessagesNotifier create() => SubSessionMessagesNotifier();

  @override
  bool operator ==(Object other) {
    return other is SubSessionMessagesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subSessionMessagesNotifierHash() =>
    r'1efa5c7d348a6dcec97af0262b37bb586afc4763';

/// 子 Session 消息列表（只读，支持 SSE 实时更新）

final class SubSessionMessagesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SubSessionMessagesNotifier,
          AsyncValue<List<MessageWithParts>>,
          List<MessageWithParts>,
          FutureOr<List<MessageWithParts>>,
          String
        > {
  SubSessionMessagesNotifierFamily._()
    : super(
        retry: null,
        name: r'subSessionMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 子 Session 消息列表（只读，支持 SSE 实时更新）

  SubSessionMessagesNotifierProvider call(String sessionID) =>
      SubSessionMessagesNotifierProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'subSessionMessagesProvider';
}

/// 子 Session 消息列表（只读，支持 SSE 实时更新）

abstract class _$SubSessionMessagesNotifier
    extends $AsyncNotifier<List<MessageWithParts>> {
  late final _$args = ref.$arg as String;
  String get sessionID => _$args;

  FutureOr<List<MessageWithParts>> build(String sessionID);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MessageWithParts>>, List<MessageWithParts>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MessageWithParts>>,
                List<MessageWithParts>
              >,
              AsyncValue<List<MessageWithParts>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
