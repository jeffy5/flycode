import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/provider_api.dart';
import '../service/api/models/provider.dart';

part 'provider_list_provider.g.dart';

@riverpod
class ProviderList extends _$ProviderList {
  @override
  Future<ProviderListResponse> build() async {
    return _load(forceRefresh: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }

  Future<ProviderListResponse> _load({required bool forceRefresh}) async {
    final api = await ref.watch(providerApiProvider.future);
    return api.list(forceRefresh: forceRefresh);
  }
}
