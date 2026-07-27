# Refs | Riverpod

Refs are the primary way to interact with [Providers](/docs/concepts2/providers).
Refs are fairly similar to the `BuildContext` in Flutter, but for providers instead of widgets.
A non-exhaustive list of things you can do with a ref:

*   read/observe the state of a provider
*   check if a provider currently is loaded or
*   reset the state of a provider

On top of that, [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html) also enables a provider to observe life-cycles about its own state.
Think "initState" and "dispose", but for providers. This includes methods such as:

*   [onDispose](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/onDispose.html)
*   [onCancel](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/onCancel.html)
*   etc.

## How to obtain a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html)

Obtaining a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html) depends on where you are in your app.

Providers naturally have access to a Ref. You can find it as parameter of the initializer function, or as a property of Notifier classes.

**riverpod**
```dart
final myProvider = Provider<int>((ref) {
  // ref is available here
  ...
});

final myNotifierProvider = NotifierProvider<MyNotifier, int>(MyNotifier.new);

class MyNotifier extends Notifier<int> {
  @override
  int build() {
    // this.ref is available anywhere inside notifiers
    ref.watch(someProvider);
    ...
  }
}
```

**riverpod_generator**
```dart
@riverpod
int myProvider(Ref ref) {
  // ref is available here
  ...
}

@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  int build() {
    // this.ref is available anywhere inside notifiers
    ref.watch(someProvider);
    ...
  }
}
```

To obtain a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html) inside widgets, you need [Consumers](/docs/concepts2/consumers).

```dart
Consumer(
  builder: (context, ref, _) {
    // ref is available here
    final value = ref.watch(myProvider);
    return Text('$value');
  },
);
```

**I am never inside a widget, nor a provider. How do I get a Ref then?**
If you are neither inside widgets nor providers, chances are whatever you are using is still loosely connected to a widget/provider.

In that case, simply pass the ref you obtained from your widget/provider to your function/object of choice:

```dart
void myFunction(WidgetRef ref) {
  // You can pass the ref around!
}

...

Consumer(
  builder: (context, ref, _) {
    return ElevatedButton(
      onPressed: () => myFunction(ref), // Pass the ref to your function
      child: const Text('Click me'),
    );
  },
);
```

## Using Refs to interact with providers

Interactions with providers generally fall under two categories:

*   Listening to a provider's state
*   Modifying a provider's state

### Listening to a provider's state

Riverpod offers two ways to listen to a provider's state:

*   [Ref.watch](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/watch.html) - This is a "declarative" way of listening to providers.
    It is the most common way to listen to providers, and should be your go to choice.
*   [Ref.listen](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/listen.html) - This is a "manual" way of listening to providers.
    It uses a typical "addListener" style of listening. Powerful, but more complex.

For the following examples, consider a provider that updates every second:

**riverpod**
```dart
final tickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (count) => count);
});
```

**riverpod_generator**
```dart
@riverpod
Stream<int> tick(Ref ref) {
  return Stream.periodic(const Duration(seconds: 1), (count) => count);
}
```

#### `Ref.watch`

[Ref.watch](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/watch.html) enables you to declare a dependency on a provider and easily have your UI update when a provider's state changes.

Using [Ref.watch](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/watch.html) is similar to using an `InheritedWidget` in Flutter.
In Flutter, when you call `Theme.of(context)`, your widget subscribes to the `Theme` and will rebuild whenever the `Theme` changes. Similarly, when you call `ref.watch(myProvider)`, your widget/provider subscribes to `myProvider`, and will rebuild whenever `myProvider` changes.

The following code shows a [Consumers](/docs/concepts2/consumers) that automatically updates whenever our `Tick` provider updates:

```dart
Consumer(
  builder: (context, ref, _) {
    final tick = ref.watch(tickProvider);
    return Text('$tick');
  },
);
```

This also applies to providers. For example, we could create a provider that returns "is tick divisible by 4?":

**riverpod**
```dart
final isDivisibleBy4 = Provider<bool>((ref) {
  final tick = ref.watch(tickProvider).value;
  return tick % 4 == 0;
});
```

**riverpod_generator**
```dart
@riverpod
bool isDivisibleBy4(Ref ref) {
  final tick = ref.watch(tickProvider).value;
  return tick % 4 == 0;
}
```

This provider will only update when the boolean value changes.

#### `Ref.listen`

[Ref.listen](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/listen.html) is a more manual way of listening to providers.
It is similar to the `addListener` method of `ChangeNotifier`, or the `Stream.listen` method.

This method is useful when you want to perform a side-effect when a provider's state changes, such as

*   Showing a dialog
*   Navigating to a new screen
*   Logging a message
*   etc.

**riverpod**
```dart
final exampleProvider = Provider<int>((ref) => 0);

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(exampleProvider, (prev, next) {
      if (next == 5) {
        showDialog(context: context, builder: (_) => AlertDialog(content: Text('Value is 5')));
      }
    });
    return Container();
  }
}
```

**riverpod_generator**
```dart
@riverpod
int example(Ref ref) => 0;

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(exampleProvider, (prev, next) {
      if (next == 5) {
        showDialog(context: context, builder: (_) => AlertDialog(content: Text('Value is 5')));
      }
    });
    return Container();
  }
}
```

In widgets, you typically call `ref.listen` inside the `build` method. Although, this is not a strict rule. You could also call it inside `initState` or `State.didUpdateWidget`.

#### `Ref.read`

[Ref.read](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/read.html) is used to obtain a provider's value without listening to it.

This is useful for:

*   One-off reads of a provider's value.
*   Calling methods on a provider's notifier (e.g., `ref.read(myProvider.notifier).doSomething()`).

In the second scenario, we do not want to "listen" to the state. For this case, [Ref.read](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/read.html) exists.

You can safely call [Ref.read](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/read.html) button clicks to perform work. The following example will print the current tick value when the button is clicked:

```dart
Consumer(
  builder: (context, ref, _) {
    return ElevatedButton(
      onPressed: () => print(ref.read(tickProvider)),
      child: const Text('Print tick'),
    );
  },
);
```

> Avoid using `ref.read` to filter rebuilds.
> This will make your code more brittle, as changes in your provider's behavior could cause your UI to be out of sync with the provider's state.
> Instead, use [Ref.watch](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/watch.html) anyway (as the difference is negligible) or use [select](https://pub.dev/documentation/hooks_riverpod/latest/misc/ProviderListenable/select.html):
>
> ```dart
> Consumer(
>   builder: (context, ref, _) {
>     // ❌ Don't use "read" as a mean to ignore changes
>     // final value = ref.read(myProvider);
>     // ...
>
>     // ✅ Do this instead
>     final value = ref.watch(myProvider.select((value) => value.field));
>     // ...
>   },
> );
> ```

### Other life-cycles events (`onDispose`, `onCancel`, `onResume`)

Refs also expose various life-cycle events that you can listen to.
These events are similar to the `initState`, `dispose`, and other life-cycle methods in Flutter widgets.

Life-cycles listeners are registered using an "addListener" style API.
Listeners are methods with a name that starts with `on`, such as [onDispose](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/onDispose.html) or [onCancel](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref/onCancel.html).

**riverpod**
```dart
final counterProvider = Provider<int>((ref) {
  // Register a cleanup function to execute when the provider is destroyed.
  ref.onDispose(() => print('Provider disposed'));
  return 0;
});
```

**riverpod_generator**
```dart
@riverpod
int counter(Ref ref) {
  // Register a cleanup function to execute when the provider is destroyed.
  ref.onDispose(() => print('Provider disposed'));
  return 0;
}
```

> You can call `ref.onDispose` as many times as you wish.
> Feel free to call it once per disposable object in your provider. This practice makes it easier to spot when we forget to dispose of something.

> The callback of `ref.onDispose` must not trigger side-effects.
> Modifying providers inside `onDispose` could lead to unexpected behavior.

These listeners are automatically cleaned up when the provider is reset.
Although if you wish to unregister them manually, you can do so by using the return value of the listener method.

```dart
final unregister = ref.onDispose(() => print('This will never be called'));
unregister();
```