import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_view_state_provider.g.dart';

typedef ChatViewState = ({String? sessionId, bool isPending});

@Riverpod(keepAlive: true)
class ChatViewStateNotifier extends _$ChatViewStateNotifier {
  @override
  ChatViewState build() => (sessionId: null, isPending: false);

  void selectSessionId(String? sessionId) {
    state = (sessionId: sessionId, isPending: false);
  }

  void startNew() {
    state = (sessionId: null, isPending: true);
  }

  void clear() {
    state = (sessionId: null, isPending: false);
  }
}
