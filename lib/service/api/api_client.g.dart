// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiHttpClientFactory)
final apiHttpClientFactoryProvider = ApiHttpClientFactoryProvider._();

final class ApiHttpClientFactoryProvider
    extends
        $FunctionalProvider<
          HttpClientFactory,
          HttpClientFactory,
          HttpClientFactory
        >
    with $Provider<HttpClientFactory> {
  ApiHttpClientFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiHttpClientFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiHttpClientFactoryHash();

  @$internal
  @override
  $ProviderElement<HttpClientFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HttpClientFactory create(Ref ref) {
    return apiHttpClientFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HttpClientFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HttpClientFactory>(value),
    );
  }
}

String _$apiHttpClientFactoryHash() =>
    r'cf45485d7414ba828e3196ba4dfb8ead85706041';

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

final class ApiClientProvider
    extends
        $FunctionalProvider<
          AsyncValue<ApiClient>,
          ApiClient,
          FutureOr<ApiClient>
        >
    with $FutureModifier<ApiClient>, $FutureProvider<ApiClient> {
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $FutureProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ApiClient> create(Ref ref) {
    return apiClient(ref);
  }
}

String _$apiClientHash() => r'4f8b1738fdb607a3f69ff0878ecc9384963020aa';
