# ProviderContainers/ProviderScopes | Riverpod

[ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html) is *the* central piece of Riverpod's architecture.
In Riverpod, [Providers](/docs/concepts2/providers) hold no state themselves. Instead, the state of a given provider is stored inside this container object.

[ProviderScope](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderScope-class.html) is a widget that creates a [ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html) and exposes it to the widget tree. Hence why, when you use Riverpod, you will always see a scope at the root of apps.
Without it, Riverpod would be unable to store the state of providers!

### Using a ProviderContainer for pure Dart applications

[ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html) is a useful object when you want to use Riverpod in pure Dart codebases, such as command-line applications or server-side applications.

You can create a [ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html) inside your `main`, and use it to read and modify providers:

```dart
import 'package:riverpod/riverpod.dart';

void main() {
  final container = ProviderContainer();

  try {
    final sub = container.listen(counterProvider, (previous, next) {
      print('Counter changed from $previous to $next');
    });
    print('Counter starts at ${sub.read()}');
  } finally {
    // Dispose the container when done
    container.dispose();
  }
}
```

> Inside tests, do not use [ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html) directly.
> Use [ProviderContainer.test](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer/ProviderContainer.test.html) instead.
> This will automatically dispose the container when the test ends.
>
> ```dart
> test('Counter starts at 0 and can be incremented', () {
>   // No need to dispose the container when the test ends
>   final container = ProviderContainer.test();
>
>   // Use the container to test your providers
> })
> ```

### Using a ProviderScope for Flutter applications

In Flutter applications, you shouldn't use [ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html) directly.
Instead, you should use [ProviderScope](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderScope-class.html), which is a widget equivalent of [ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html).

The end-result is the same: Create a [ProviderScope](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderScope-class.html) in your `main`. After that, you can use [Consumers](/docs/concepts2/consumers) to read and modify providers in your widgets.

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final counter = ref.watch(counterProvider);

          // TODO use "counter"
        },
      ),
    ),
  );
}
```

## Why store the state of providers inside a container?

One might wonder why providers don't store their state themselves.
If we got rid of that requirement, we could imagine a world where we could write:

```dart
print(helloWorldProvider.value); // Prints "Hello world!"
```

instead of having to write `ref.watch(helloWorldProvider)`.

Riverpod does this for a few reasons, which come down the same logic: "No global state".

1.  Better separation of concerns.
    If Riverpod were to allow providers to store their own state, it would imply that *anything* could read/write to that state. This means that it would be difficult to control how/when a state is modified.

    Using Riverpod's architecture, state updates are centralized: All the logic for modifying a provider is done in the provider itself. And generally, the UI will only invoke one method on the provider's Notifier.

2.  Better testing.
    By storing the state of providers inside a container, we do not have to worry about resetting the application state between tests. We can simply create a new container for each test, and a fresh state will be created for each provider:

    ```dart
    test('Counter starts at 0 and can be incremented', () {
      final container = ProviderContainer.test();

      expect(container.read(counterProvider), 0);
      container.read(counterProvider.notifier).increment();
      expect(container.read(counterProvider), 1);
    });
    ```

    This ensures that changes inside one test do not affect the other test.

    Of course, the same applies when using [ProviderScope](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderScope-class.html) and widget tests.

3.  A centralized place for configuring your application.
    Through [ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html) and [ProviderScope](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderScope-class.html), we can configure various app-wide aspects of Riverpod. For example:

    *   We can define a custom [ProviderObserver](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderObserver-class.html) to listen to all state changes in the app.
        See [ProviderObservers](/docs/concepts2/observers).
    *   We can override providers, either locally or globally. This can be useful for testing or for applications with different environments, or for development.
        See [Provider overrides](/docs/concepts2/overrides).

4.  Support for [Scoping providers](/docs/concepts2/scoping).
    By storing the state of a provider inside a container, we can have the same provider resolve to a different state depending on where in the widget tree it is used.
    This feature is quite advanced and generally discouraged, but useful for performance optimizations.