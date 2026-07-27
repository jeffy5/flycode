# Automatic retry | Riverpod

In Riverpod, [Providers](/docs/concepts2/providers) are automatically retried when they fail.

A retry is attempted when an exception is thrown during the provider's computation.
The retry logic can be customized either on a per-provider basis or globally for all providers.

By default, a provider can be retried up to 10 times, with an exponential backoff going from 200ms to 6.4 seconds.
For the full details about the default retry logic, see [retry](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer/retry.html).

## Customizing retry logic

A custom retry logic can be provided either for the full application or for a specific provider.

The implementation is the same for both cases: Custom retry logic is a function that is expected to return a `Duration?` value ; which indicates the delay before the next retry (or `null` to stop retrying).

The following implements a custom [retry](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer/retry.html) function, which will retry up to 5 times, with an exponential backoff starting at 200ms, and ignores [ProviderException](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderException-class.html)s

```dart
Duration? myRetry(int retryCount, Object error) {
  // Stop retrying on ProviderException
  if (retryCount >= 5) return null;
  // Ignore ProviderException
  if (error is ProviderException) return null;

  return Duration(milliseconds: 200 * (1 << retryCount)); // Exponential backoff
}
```

This function can then be used either inside providers to update the retry logic for that specific provider:

**riverpod**
```dart
final myProvider = Provider<int>(
    retry: myRetry,
    (ref) => 0,
  );
```

**riverpod_generator**
```dart
@Riverpod(retry: myRetry)
int myProvider(MyProviderRef ref) {
  return 0;
}
```

Or globally by passing it to [ProviderContainers/ProviderScopes](/docs/concepts2/containers):

```dart
// For pure Dart code
final container = ProviderContainer(
  retry: myRetry,
);

...

// For Flutter code
runApp(
  ProviderScope(
    retry: myRetry,
    child: MyApp(),
  ),
);
```

### Disabling retry

Disabling retry is as simple as always retuning `null` in the retry function.
If you wish to disable retry for all your application, do:

```dart
runApp(
  ProviderScope(
    retry: (retryCount, error) => null,
    child: MyApp(),
  ),
);
```

## About the default retry logic

The default retry logic is designed to be a more more clever than a naive "if fail, retry".
In particular, it will not retry [Error](https://api.dart.dev/stable/2.19.6/dart-core/Error-class.html)s and [ProviderException](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderException-class.html)s.

Errors are not retried, because they are not recoverable. They indicate a bug in the code, and retrying would not help. Retrying in those cases would just pollute the logs with useless retry attempts.

As for ProviderExceptions, those are not retried because they indicate that a provider did not fail, but instead rethrow an exception from a failed provider. Consider:

**riverpod**
```dart
final failedProvider = Provider<int>(
  (ref) => throw Exception(),
);

final myProvider = Provider<int>((ref) {
  return ref.watch(failedProvider);
});
```

**riverpod_generator**
```dart
@riverpod
int failed(Ref ref) => throw Exception();

@riverpod
int myProvider(Ref ref) {
  return ref.watch(failedProvider);
}
```

In this example, <code>myProvider</code> would rethrow the exception from <code>failedProvider</code>.
Retrying it would not help. Instead, it is <code>failedProvider</code> that should be retried.

This implies that if you disable retry for <code>failedProvider</code>, then <code>myProvider</code> will also not be retried.

## Awaiting for retries to complete

You may be aware that you can await for asynchronous providers to complete, by using [FutureProvider.future](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/FutureProvider/future.html):

```dart
final value = await ref.watch(myProvider.future);
```

This will make your UI wait for your provider to complete. If the provider fails, your UI will receive an exception.

In the presence of retry, `ref.watch(myProvider.future)` will keep waiting until either:

*   all retries are exhausted, or
*   the provider succeeds.

This ensures that `await ref.watch(myProvider.future)` skips the intermediate failures.