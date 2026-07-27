import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/server_config.dart';
import 'local_preferences_repository.dart';

part 'server_config_provider.g.dart';

@Riverpod(keepAlive: true)
class ServerConfigNotifier extends _$ServerConfigNotifier {
  @override
  Future<ServerConfig> build() async {
    final repository = ref.watch(localPreferencesRepositoryProvider);
    return repository.loadServerConfig();
  }

  Future<void> save(ServerConfig config) async {
    final repository = ref.read(localPreferencesRepositoryProvider);
    await repository.saveServerConfig(config);
    state = AsyncData(config);
  }

  Future<void> clear() async {
    final repository = ref.read(localPreferencesRepositoryProvider);
    await repository.clearServerConfig();
    state = AsyncData(ServerConfig.defaultValue());
  }
}
