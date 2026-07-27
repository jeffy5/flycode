# Providers | Riverpod

Providers are the central feature of Riverpod. If you use Riverpod, you use it for its providers.

## What is a provider?

Providers are essentially "memoized functions", with sugar on top.
What this means is, providers are functions which will return a cached value when called with the same parameters.

The most common use-case for using providers is to perform a network request.
Consider a function that fetches a user from an API:

```dart
Future<User> fetchUser() async {
  final response = await http.get('https://api.example.com/user/123');
  return User.fromJson(response.body);
}
```

One issue with this function is, if we were to try using it inside widgets, we'd have to cache the result ourselves ; then figure out a way to share the value across all widgets that need it.

That is where providers come in. Providers are wrappers around functions.
They will cache the result of said function and allow multiple widgets to access the same value:

**riverpod**
```dart
// The equivalent of our fetchUser function, but the result is cached.
// Using userProvider multiple times will return the same value.
final userProvider = FutureProvider<User>((ref) async {
  final response = await http.get('https://api.example.com/user/123');
  return User.fromJson(response.body);
});
```

**riverpod_generator**
```dart
// The equivalent of our fetchUser function, but the result is cached.
// This will generate a "userProvider". Using it multiple times will
// return the same value.
@riverpod
Future<User> user(Ref ref) async {
  final response = await http.get('https://api.example.com/user/123');
  return User.fromJson(response.body);
}
```

On top of basic caching, providers then add various features to make them more powerful:

*   **Built-in cache invalidation mechanisms**
    In particular, [Ref.watch](https://pub.dev/documentation/riverpod/latest/riverpod/Ref/watch.html) allows you to combine caches together, automatically invalidating what is needed.
*   **[Automatic disposal](/docs/concepts2/auto_dispose)**
    Providers can automatically release resources when they are no longer needed.
*   **Data-binding**
    Providers remove the need for a [FutureBuilder](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html) or a [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html).
*   **Automatic error handling**
    Providers can automatically catch errors and expose them to the UI.
*   **Mocking support**
    For better testing and other purposes, all providers can be mocked.
    See [Provider overrides](/docs/concepts2/overrides).
*   **[Offline persistence (experimental)](/docs/concepts2/offline)**
    The result of a provider can be persisted to disk and automatically reloaded when the app is restarted.
*   **[Mutations (experimental)](/docs/concepts2/mutations)**
    Providers offer a built-in way for UIs render a spinner/error for side effects (such as form submission).

Providers come 6 variants:

| | Synchronous | Future | Stream |
|---|---|---|---|
| Unmodifiable | [Provider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Provider-class.html) | [FutureProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/FutureProvider-class.html) | [StreamProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/StreamProvider-class.html) |
| Modifiable | [NotifierProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/NotifierProvider-class.html) | [AsyncNotifierProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/AsyncNotifierProvider-class.html) | [StreamNotifierProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/StreamNotifierProvider-class.html) |

This may seem overwhelming at first. Let's break it down.

**Sync** vs **Future** vs **Stream**:
The columns of this table represent the built-in Dart types for functions.

```dart
int synchronous() => 0;
Future<int> future() async => 0;
Stream<int> stream() => Stream.value(0);
```

**Unmodifiable vs Modifiable**:
By default, providers are not modifiable by widgets. The "Notifier" variant of providers make them externally modifiable.
This is similar to a private setter ("unmodifiable" providers)

```dart
// _state is internally modifiable
// but cannot be modified externally
var _state = 0;
int get state => _state;
```

VS a public setter ("modifiable" providers)

```dart
// Anything can modify "state"
var state = 0;
```

> You can also view **unmodifiable** vs **modifiable** as respectively `StatelessWidget` vs `StatefulWidget` in principle.  
> This is not entirely accurate, as providers are not widgets and both kinds store "state".
> But the principle is similar: "One object, immutable" vs "Two objects, mutable".

## Creating a provider

Providers should be created as "top-level" declarations.
This means that they should be declared outside of any class or function.

The syntax for creating a provider depends on whether it is "modifiable" or "unmodifiable", as per the table above.

**Unmodifiable (functional)**

**riverpod**

```
final name = SomeProvider.someModifier<Result>((ref) {
  <your logic here>
});
```

*   **The provider variable**: This variable is what will be used to interact with our provider.
    The variable must be final and "top-level" (global).

    > Do not be frightened by the global aspect of providers.
    > Providers are fully immutable. Declaring a provider is no different from declaring a function, and providers are testable and maintainable.

*   **The provider type**: Generally either [Provider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Provider-class.html), [FutureProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/FutureProvider-class.html) or [StreamProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/StreamProvider-class.html).
    The type of provider used depends on the return value of your function.
    For example, to create a `Future<Activity>`, you'll want a `FutureProvider<Activity>`.

    `FutureProvider` is the one you'll want to use the most.

    > Don't think in terms of "Which provider should I pick".
    > Instead, think in terms of "What do I want to return". The provider type will follow naturally.

*   **Modifiers (optional)**: Often, after the type of the provider you may see a "modifier".
    Modifiers are optional, and are used to tweak the behavior of the provider in a way that is type-safe.

    There are currently two modifiers available:

    *   `autoDispose`, which will automatically clear the cache when the provider stops being used.
        See also [Automatic disposal](/docs/concepts2/auto_dispose)
    *   `family`, which enables passing arguments to your provider.
        See also [Family](/docs/concepts2/family).

*   **Ref**: An object used to interact with other providers.
    All providers have one; either as parameter of the provider function, or as a property of a Notifier.

*   **The provider function**: This is where we place the logic of our providers.
    This function will be called when the provider is first read.
    Subsequent reads will not call the function again, but instead return the cached value.

**riverpod_generator**

```
@riverpod
Result myFunction(Ref ref) {
  <your logic here>
}
```

*   **The annotation**: All generated providers must be annotated with `@riverpod` or `@Riverpod()`.
    This annotation can be placed on global functions or classes. Through this annotation, it is possible to configure the provider.

    For example, we can disable "auto-dispose" (which we will see later) by writing `@Riverpod(keepAlive: true)`.

*   **The annotated function**: The name of the annotated function determines how the provider will be interacted with.
    For a given function `myFunction`, a `myFunctionProvider` will be generated.

    Annotated functions **must** specify a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html) as first parameter.
    Besides that, the function can have any number of parameters, including generics.
    The function is also free to return a `Future`/`Stream` if it wishes to.

    This function will be called when the provider is first read.
    Subsequent reads will not call the function again, but instead return the cached value.

*   **Ref**: An object used to interact with other providers.
    All providers have one; either as parameter of the provider function, or as a property of a Notifier.
    The type of this object is determined by the name of the function/class.

**Modifiable (notifier)**

**riverpod**

```
final name = SomeNotifierProvider.someModifier<MyNotifier, Result>(MyNotifier.new);
 
class MyNotifier extends SomeNotifier<Result> {
  @override
  Result build() {
    <your logic here>
  }
  <your methods here>
}
```

*   **The provider variable**: This variable is what will be used to interact with our provider.
    The variable must be final and "top-level" (global).

    > Do not be frightened by the global aspect of providers.
    > Providers are fully immutable. Declaring a provider is no different from declaring a function, and providers are testable and maintainable.

*   **The provider type**: Generally either [NotifierProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/NotifierProvider-class.html), [AsyncNotifierProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/AsyncNotifierProvider-class.html) or [StreamNotifierProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/StreamNotifierProvider-class.html).
    The type of provider used depends on the return value of your function.
    For example, to create a `Future<Activity>`, you'll want a `AsyncNotifierProvider<Activity>`.

    [AsyncNotifierProvider](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/AsyncNotifierProvider-class.html) is the one you'll want to use the most.

    > As with functional providers, don't think in terms of "Which provider should I pick".
    > Create whatever state you want to create, and the provider type will follow naturally.

*   **Modifiers (optional)**: Often, after the type of the provider you may see a "modifier".
    Modifiers are optional, and are used to tweak the behavior of the provider in a way that is type-safe.

    There are currently two modifiers available:

    *   `autoDispose`, which will automatically clear the cache when the provider stops being used.
        See also [Automatic disposal](/docs/concepts2/auto_dispose)
    *   `family`, which enables passing arguments to your provider.
        See also [Family](/docs/concepts2/family).

*   **The Notifier's constructor**: The parameter of "notifier providers" is a function which is expected to instantiate the "notifier".
    It generally should be a "constructor tear-off".

*   **The Notifier**: If `NotifierProvider` is equivalent to `StatefulWidget`, then this part is the `State` class.

    This class is responsible for exposing ways to modify the state of the provider.
    Public methods on this class are accessible to consumers using `ref.read(yourProvider.notifier).yourMethod()`.

    > Do not put logic in the constructor of your notifier.
    > Notifiers should not have a constructor, as `ref` and other properties aren't yet available at that point. Instead, put your logic in the `build` method.

    Some examples would be:

    *   NotifierProvider -> Notifier
    *   AsyncNotifierProvider -> AsyncNotifier
    *   StreamNotifierProvider -> StreamNotifier

*   **The build method**: All notifiers must override the `build` method.
    This method is equivalent to the place where you would normally put your logic in a non-notifier provider.

    This method should not be called directly.

**riverpod_generator**

```
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  Result build() {
    <your logic here>
  }
  <your methods here>
}
```

*   **The annotation**: All providers must be annotated with `@riverpod` or `@Riverpod()`.
    This annotation can be placed on global functions or classes.
    Through this annotation, it is possible to configure the provider.

    For example, we can disable "auto-dispose" (which we will see later) by writing `@Riverpod(keepAlive: true)`.

*   **The Notifier**: When a `@riverpod` annotation is placed on a class, that class is called a "Notifier".
    The class must extend `_$NotifierName`, where `NotifierName` is the class name.

    Notifiers are responsible for exposing ways to modify the state of the provider.
    Public methods on this class are accessible to consumers using `ref.read(yourProvider.notifier).yourMethod()`.

    > Do not put logic in the constructor of your notifier.
    > Notifiers should not have a constructor, as `ref` and other properties aren't yet available at that point. Instead, put your logic in the `build` method.

*   **The build method**: All notifiers must override the `build` method.
    This method is equivalent to the place where you would normally put your logic in a non-notifier provider.

    This method should not be called directly.

> You can declare as many providers as you want without limitations.
> As opposed to when using `package:provider`, Riverpod allows creating multiple providers exposing a state of the same "type":

**riverpod**

```dart
final cityProvider = Provider((ref) => 'London');
final countryProvider = Provider((ref) => 'England');
```

> Similarly to how widgets are a description of the UI, providers are a description of the state.
> Surprisingly, a provider is fully stateless, and could be instantiated as `const` if not for the fact that this would make the syntax a bit more verbose.

To use a provider, you need a separate object: [ProviderContainer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderContainer-class.html).
See [ProviderContainers/ProviderScopes](/docs/concepts2/containers) for more information.

Long story short, before you can use a provider, wrap your Flutter applications in a [ProviderScope](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ProviderScope-class.html):

```dart
void main() {
  runApp(ProviderScope(child: MyApp()));
}
```

Providers typically get access to a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html).
See [Refs](/docs/concepts2/refs) for information about those.

In short, there are two ways to obtain a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html):

*   Providers naturally get access to one.
    This is the first parameter of the provider function, or the `ref` property of a Notifier.
    This enables providers to communicate with each other.
*   The Widget tree will need special kind of widgets, called [Consumers](/docs/concepts2/consumers).
    Those widgets bridge the gap between the widget tree and the provider tree, by giving you a [WidgetRef](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/WidgetRef-class.html).

As example, consider a `helloWorldProvider` that returns a simple string.
You could use it inside widgets like this:

```dart
class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final value = ref.watch(helloWorldProvider);
        return Text(value);
      },
    );
  }
}
```
