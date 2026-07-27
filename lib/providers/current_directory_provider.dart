import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_directory_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentDirectory extends _$CurrentDirectory {
  @override
  String? build() => null;

  void set(String? directory) {
    final value = directory?.trim();
    state = (value == null || value.isEmpty) ? null : value;
  }

  void clear() {
    state = null;
  }
}
