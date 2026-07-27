import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/shared_preferences_provider.dart';
import 'api_client.dart';
import 'models/provider.dart';

part 'provider_api.g.dart';

const String _providerListCachePrefix = 'provider_list_cache';

@Riverpod(keepAlive: true)
Future<ProviderApi> providerApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return ProviderApi(
    client,
    preferencesLoader: () => ref.read(sharedPreferencesProvider.future),
  );
}

class ProviderApi {
  final ApiClient _client;
  final Future<SharedPreferences> Function() _preferencesLoader;

  ProviderApi(
    this._client, {
    required Future<SharedPreferences> Function() preferencesLoader,
  }) : _preferencesLoader = preferencesLoader;

  Future<ProviderListResponse> list({
    String? directory,
    bool forceRefresh = false,
    Duration cacheTtl = const Duration(minutes: 10),
  }) async {
    final cacheKey = _cacheKey(directory);
    final prefs = await _preferencesLoader();
    final cached = _readCache(
      prefs: prefs,
      cacheKey: cacheKey,
      cacheTtl: cacheTtl,
      allowExpired: false,
    );

    if (!forceRefresh && cached != null) {
      return ProviderListResponse.fromJson(cached);
    }

    try {
      final json = await _client.get(
        '/provider',
        queryParameters: directory != null ? {'directory': directory} : null,
      );
      final map = json as Map<String, dynamic>;
      await _writeCache(prefs: prefs, cacheKey: cacheKey, data: map);
      return ProviderListResponse.fromJson(map);
    } catch (_) {
      final fallback = _readCache(
        prefs: prefs,
        cacheKey: cacheKey,
        cacheTtl: cacheTtl,
        allowExpired: true,
      );
      if (fallback != null) {
        return ProviderListResponse.fromJson(fallback);
      }
      rethrow;
    }
  }

  String _cacheKey(String? directory) {
    final scopedDirectory = directory?.trim().isNotEmpty == true
        ? directory!.trim()
        : 'root';
    return '$_providerListCachePrefix::${_client.baseUrl}::$scopedDirectory';
  }

  Map<String, dynamic>? _readCache({
    required SharedPreferences prefs,
    required String cacheKey,
    required Duration cacheTtl,
    required bool allowExpired,
  }) {
    final raw = prefs.getString(cacheKey);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAtMs = decoded['cachedAt'] as int?;
      final data = decoded['data'];
      if (cachedAtMs == null || data is! Map<String, dynamic>) {
        return null;
      }

      if (!allowExpired) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
        final isExpired = DateTime.now().difference(cachedAt) > cacheTtl;
        if (isExpired) {
          return null;
        }
      }

      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache({
    required SharedPreferences prefs,
    required String cacheKey,
    required Map<String, dynamic> data,
  }) async {
    final payload = <String, dynamic>{
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await prefs.setString(cacheKey, jsonEncode(payload));
  }
}
