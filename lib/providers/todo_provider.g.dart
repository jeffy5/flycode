// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表

@ProviderFor(SessionTodosNotifier)
final sessionTodosProvider = SessionTodosNotifierFamily._();

/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
final class SessionTodosNotifierProvider
    extends $AsyncNotifierProvider<SessionTodosNotifier, List<Todo>> {
  /// 按 sessionID 管理 todo 列表的 family provider。
  ///
  /// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
  /// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
  SessionTodosNotifierProvider._({
    required SessionTodosNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionTodosProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionTodosNotifierHash();

  @override
  String toString() {
    return r'sessionTodosProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionTodosNotifier create() => SessionTodosNotifier();

  @override
  bool operator ==(Object other) {
    return other is SessionTodosNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionTodosNotifierHash() =>
    r'9e82b817c2442e1410a0c24cc5ff9c5f4175aa52';

/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表

final class SessionTodosNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionTodosNotifier,
          AsyncValue<List<Todo>>,
          List<Todo>,
          FutureOr<List<Todo>>,
          String
        > {
  SessionTodosNotifierFamily._()
    : super(
        retry: null,
        name: r'sessionTodosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 按 sessionID 管理 todo 列表的 family provider。
  ///
  /// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
  /// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表

  SessionTodosNotifierProvider call(String sessionID) =>
      SessionTodosNotifierProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'sessionTodosProvider';
}

/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表

abstract class _$SessionTodosNotifier extends $AsyncNotifier<List<Todo>> {
  late final _$args = ref.$arg as String;
  String get sessionID => _$args;

  FutureOr<List<Todo>> build(String sessionID);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Todo>>, List<Todo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Todo>>, List<Todo>>,
              AsyncValue<List<Todo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
