import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/question.dart';
import '../service/api/question_api.dart';
import 'current_directory_provider.dart';

part 'question_provider.g.dart';

/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.
@Riverpod()
class PendingQuestionsNotifier extends _$PendingQuestionsNotifier {
  @override
  Future<List<QuestionRequest>> build() async {
    final directory = ref.watch(currentDirectoryProvider);
    final api = await ref.watch(questionApiProvider.future);
    return api.getQuestions(directory: directory);
  }

  /// SSE: question.asked — add a new question to the list.
  void addQuestion(QuestionRequest request) {
    final current = state.asData?.value ?? [];
    // Avoid duplicates
    if (current.any((q) => q.id == request.id)) return;
    state = AsyncData([...current, request]);
  }

  /// SSE: question.replied or question.rejected — remove question from list.
  void removeQuestion(String requestID) {
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((q) => q.id != requestID).toList());
  }

  /// Submit answers for a question and remove it from the list.
  Future<void> reply(
    String requestID, {
    required List<List<String>> answers,
    String? directory,
  }) async {
    final api = await ref.read(questionApiProvider.future);
    await api.replyQuestion(requestID, answers: answers, directory: directory);
    removeQuestion(requestID);
  }

  /// Reject a question and remove it from the list.
  Future<void> reject(String requestID, {String? directory}) async {
    final api = await ref.read(questionApiProvider.future);
    await api.rejectQuestion(requestID, directory: directory);
    removeQuestion(requestID);
  }
}

@Riverpod()
bool currentSessionHasQuestion(Ref ref, String sessionId) {
  final questions = ref.watch(pendingQuestionsProvider);
  return questions.asData?.value.any((q) => q.sessionID == sessionId) ?? false;
}
