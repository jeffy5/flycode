import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/global_event.dart' show Todo;
import '../service/api/session_api.dart';

part 'todo_provider.g.dart';

/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
@Riverpod()
class SessionTodosNotifier extends _$SessionTodosNotifier {
  @override
  Future<List<Todo>> build(String sessionID) async {
    final api = await ref.read(sessionApiProvider.future);
    return api.getSessionTodos(sessionID);
  }

  /// SSE: todo.updated — 全量替换当前 todo 列表。
  void updateTodos(List<Todo> todos) {
    state = AsyncData(todos);
  }
}
