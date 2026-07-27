import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flycode/service/api/global_api.dart';

final globalEventConnectionProvider =
    NotifierProvider<GlobalEventConnection, GlobalEventConnectionState>(
      GlobalEventConnection.new,
    );

class GlobalEventConnection extends Notifier<GlobalEventConnectionState> {
  @override
  GlobalEventConnectionState build() {
    return const GlobalEventConnectionState.disconnected();
  }

  void setState(GlobalEventConnectionState next) {
    state = next;
  }
}
