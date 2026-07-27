# Automatic disposal | Riverpod

In Riverpod, it is possible to tell the framework to automatically destroy resources associated with a provider when it is no longer used.

## Enabling/disabling automatic disposal

If you're using code-generation, this is enabled by default, and can be opted out in the annotation:

```dart
// Disable automatic disposal
@Riverpod(keepAlive: true)
String helloWorld(Ref ref) => 'Hello world!';
```

If you're not using code-generation, you can enable it by using `isAutoDispose: true` when creating the provider:

```dart
final helloWorldProvider = Provider<String>(
  // Opt-in to automatic disposal
  isAutoDispose: true,
  (ref) => 'Hello world!',
);
```

> Enabling/disabling automatic disposal has no impact on whether or not the state is destroyed when the provider is recomputed.
> The state will always be destroyed when the provider is recomputed.

> When providers receive parameters, it is recommended to enable automatic disposal.
> That is because otherwise, one state per parameter combination will be created, which can lead to memory leaks.

## When is automatic disposal triggered?

When automatic disposal is enabled, Riverpod will track whether a provider has listeners or not.
This happens by tracking [Ref.watch](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/watch.html)/[Ref.listen](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/listen.html) calls (and a few others).

When that counter reaches zero, the provider is considered "not used", and [Ref.onCancel](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/onCancel.html) is triggered.
At that point, Riverpod waits for one frame (cf. `await null`). If, after that frame, the provider is still not used, then the provider is destroyed and [Ref.onDispose](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/onDispose.html) will be triggered.

## Reacting to state disposal

In Riverpod, there are a few built-in ways for state to be destroyed:

*   The provider is no longer used and is in "auto dispose" mode (more on that later).
    In this case, all associated state with the provider is destroyed.
*   The provider is recomputed, such as with `ref.watch`.
    In that case, the previous state is disposed, and a new state is created.

In both cases, you may want to execute some logic when that happens.
This can be achieved with `ref.onDispose`. This method enables registering a listener for whenever the state is destroyed.

For example, you may want to use it to close any active `StreamController`:

**riverpod**
```dart
final provider = StreamProvider<int>((ref) {
  final controller = StreamController<int>();

  // When the state is destroyed, we close the StreamController.
  ref.onDispose(controller.close);

  // TO-DO: Push some values in the StreamController
  return controller.stream;
});
```

**riverpod_generator**
```dart
@riverpod
Stream<int> example(Ref ref) {
  final controller = StreamController<int>();

  // When the state is destroyed, we close the StreamController.
  ref.onDispose(controller.close);

  // TO-DO: Push some values in the StreamController
  return controller.stream;
}
```

> The callback of `ref.onDispose` must not trigger side-effects.
> Modifying providers inside `onDispose` could lead to unexpected behavior.

> There are other useful life-cycles such as:
> *   `ref.onCancel` which is called when the last listener of a provider is removed.
> *   `ref.onResume` which is called when a new listener is added after `onCancel` was invoked.

> You can call `ref.onDispose` as many times as you wish.
> Feel free to call it once per disposable object in your provider. This practice makes it easier to spot when we forget to dispose of something.

## Manually forcing the destruction of a provider, using `ref.invalidate`

Sometimes, you may want to force the destruction of a provider.
This can be done by using `ref.invalidate`, which can be called from another provider or a widget.

Using `ref.invalidate` will destroy the current provider state.
There are then two possible outcomes:

*   If the provider is listened to, a new state will be created.
*   If the provider is not listened to, the provider will be fully destroyed.

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref.invalidate(myProvider),
      child: const Text('Invalidate myProvider'),
    );
  }
}
```

> There is also `ref.refresh`. This behaves similarly to `ref.invalidate`.
> Although in this case, this will always result in a new state being created.

> When trying to invalidate a provider which receives parameters, it is possible to either invalidate one specific parameter combination, or all parameter combinations at once:
>
> **riverpod**
> ```dart
> final provider = Provider.autoDispose.family<String, String>((
>   ref,
>   name,
> ) => 'Hello $name');
>
> // Invalidate only the provider for a specific name
> ref.invalidate(provider('John'));
>
> // Invalidate all providers created with this family
> ref.invalidate(provider);
> ```
>
> **riverpod_generator**
> ```dart
> @riverpod
> String provider(Ref ref, String name) => 'Hello $name';
>
> // Invalidate only the provider for a specific name
> ref.invalidate(providerProvider('John'));
>
> // Invalidate all providers created with this family
> ref.invalidate(providerProvider);
> ```

## Keeping state alive using `ref.keepAlive()`

When a provider has automatic disposal enabled, it will automatically destroy its state when the provider has no listeners for a full frame.

But you may want to have more control over this behavior. For instance, you may want to keep the state of successful network requests, but not cache failed requests.

This can be achieved with `ref.keepAlive`, after enabling automatic disposal.
Using it, you can decide *when* the state stops being automatically disposed.

**riverpod**
```dart
final provider = FutureProvider.autoDispose<String>((
  ref,
) async {
  try {
    final result = await http.get('api/items');
    // On success, we keep the state alive indefinitely
    // This will prevent the provider from being disposed, unless it is manually invalidated
    ref.keepAlive();
    return result;
  } catch (err) {
    // On error, we don't do anything.
    // This means the provider will still be disposed after all listeners are removed.
    rethrow;
  }
});
```

**riverpod_generator**
```dart
@riverpod
Future<String> provider(Ref ref) async {
  try {
    final result = await http.get('api/items');
    // On success, we keep the state alive indefinitely
    // This will prevent the provider from being disposed, unless it is manually invalidated
    ref.keepAlive();
    return result;
  } catch (err) {
    // On error, we don't do anything.
    // This means the provider will still be disposed after all listeners are removed.
    rethrow;
  }
}
```

## Example: keeping state alive for a specific amount of time

Currently, Riverpod does not offer a built-in way to keep state alive for a specific amount of time.
But implementing such a feature is easy and reusable with the tools we've seen so far.

By using a `Timer` + `ref.keepAlive`, we can keep the state alive for a specific amount of time.
To make this logic reusable, we could implement it in an extension method:

```dart
extension CacheForExtension on Ref {
  /// Keeps the provider alive for [duration].
  void cacheFor(Duration duration) {
    // Immediately mark the provider as "kept alive".
    final link = keepAlive();
    // When the duration expires, we release the link.
    final timer = Timer(duration, link.close);

    // If the provider is re-evaluated or disposed, cancel the timer.
    onDispose(timer.cancel);
  }
}
```

> This extension is a simple implementation. More advanced usages could include the use of `ref.onCancel`/`ref.onResume` to destroy the state only if a provider hasn't been listened to for a specific amount of time.