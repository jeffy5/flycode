import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLifecycleStateProvider =
    NotifierProvider<AppLifecycleStateNotifier, AppLifecycleState>(
      AppLifecycleStateNotifier.new,
    );

class AppLifecycleStateNotifier extends Notifier<AppLifecycleState> {
  @override
  AppLifecycleState build() {
    return WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  void setState(AppLifecycleState next) {
    if (state == next) return;
    state = next;
  }
}

bool isAppInForeground(AppLifecycleState state) {
  return state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;
}
