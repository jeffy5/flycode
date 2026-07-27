import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/question.dart';

part 'question_api.g.dart';

@riverpod
Future<QuestionApi> questionApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return QuestionApi(client);
}

class QuestionApi {
  final ApiClient _client;

  QuestionApi(this._client);

  Future<List<QuestionRequest>> getQuestions({String? directory}) async {
    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final List<dynamic> json = await _client.get(
      '/question',
      queryParameters: queryParams,
      extraHeaders: extraHeaders,
    );
    return json
        .map((e) => QuestionRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> replyQuestion(
    String requestID, {
    required List<List<String>> answers,
    String? directory,
  }) async {
    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    final result = await _client.post(
      '/question/$requestID/reply',
      body: {'answers': answers},
      extraHeaders: extraHeaders,
    );
    return result == true;
  }

  Future<bool> rejectQuestion(String requestID, {String? directory}) async {
    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    final result = await _client.post(
      '/question/$requestID/reject',
      extraHeaders: extraHeaders,
    );
    return result == true;
  }
}
