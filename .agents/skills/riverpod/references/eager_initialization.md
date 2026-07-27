# How to eagerly initialize providers | Riverpod

All providers are initialized lazily by default. This means that the provider is only initialized when it is first used. This is useful for providers that are only used in certain parts of the application.

Unfortunately, there is no way to flag a provider as needing to be eagerly initialized due to how Dart works (for tree shaking purposes). One solution, however, is to forcibly read the providers you want to eagerly initialize at the root of your application.

The recommended approach is to simply "watch" a provider in a Consumer placed right under your `ProviderScope`:

```dart
void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _EagerInitialization(
      // TODO: Render your app here
      child: MaterialApp(),
    );
  }
}

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize providers by watching them.
    // By using "watch", the provider will stay alive and not be disposed.
    ref.watch(myProvider);
    return child;
  }
}
```

> Consider putting the initialization consumer in your "MyApp" or in a public widget.
> This enables your tests to use the same behavior, by removing logic from your main.

### FAQ

#### Won't this rebuild our entire application when the provider changes?

No, this is not the case.
In the sample given above, the consumer responsible for eagerly initializing is a separate widget, which does nothing but return a `child`.

The key part is that it returns a `child`, rather than instantiating `MaterialApp` itself.
This means that if `_EagerInitialization` ever rebuilds, the `child` variable will not have changed. And when a widget doesn't change, Flutter doesn't rebuild it.

As such, only `_EagerInitialization` will rebuild, unless another widget is also listening to that provider.

#### Using this approach, how can I handle loading and error states?

You can handle loading/error states as you normally would in a `Consumer`.
Your `_EagerInitialization` could check if a provider is in a "loading" state, and if so, return a `CircularProgressIndicator` instead of the `child`:

```dart
class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(myProvider);

    // Handle error states and loading states
    if (result.isLoading) {
      return const CircularProgressIndicator();
    } else if (result.hasError) {
      return const Text('Oopsy!');
    }

    return child;
  }
}
```

#### I've handled loading/error states, but other Consumers still receive an AsyncValue! Is there a way to not have to handle loading/error states in every widget?

Rather than trying to have your provider *not* expose an `AsyncValue`, you can instead have your widgets use `AsyncValue.requireValue`.
This will read the data without having to do pattern matching. And in case a bug slips through, it will throw an exception with a clear message.

**riverpod**
```dart
// An eagerly initialized provider.
final exampleProvider = FutureProvider<String>(
  (ref) async => 'Hello',
);

// A second provider which depends on `exampleProvider`.
// This provider exposes only `String` instead of `AsyncValue<String>`.
final myProvider = Provider<String>((ref) {
  return ref.watch(exampleProvider).requireValue;
});
```

**riverpod_generator**
```dart
@riverpod
Future<String> example(Ref ref) async => 'Hello';

@riverpod
String myProvider(Ref ref) {
  return ref.watch(exampleProvider).requireValue;
}
```

> `AsyncValue.requireValue` is generally safe to use, as you've handled the loading/error states in your `_EagerInitialization` widget. However, it is generally discouraged to do so.
> The added complexity of making two providers and using overrides is not worth the trouble.