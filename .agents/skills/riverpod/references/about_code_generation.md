# About code generation | Riverpod

Code generation is the idea of using a tool to generate code for us.
In Dart, it comes with the downside of requiring an extra step to "compile" an application. Although this problem may be solved in the near future, as the Dart team is working on a potential solution to this problem.

In the context of Riverpod, code generation is about slightly changing the syntax for defining a "provider". For example, instead of:

```dart
final fetchUserProvider = FutureProvider.autoDispose.family<User, int>((
  ref,
  userId,
) async {
  final json = await http.get('api/user/$userId');
  return User.fromJson(json);
});
```

Using code generation, we would write:

```dart
@riverpod
Future<User> fetchUser(Ref ref, {required int userId}) async {
  final json = await http.get('api/user/$userId');
  return User.fromJson(json);
}
```

When using Riverpod, code generation is completely optional. It is entirely possible to use Riverpod without.
At the same time, Riverpod embraces code generation and recommends using it.

For information on how to install and use Riverpod's code generator, refer to the [Getting started](/docs/introduction/getting_started) page. Make sure to enable code generation in the documentation's sidebar.

## Should I use code generation?

Code generation is optional in Riverpod.
With that in mind, you may wonder if you should use it or not.

The answer is: **Only if you already use code-generation for other things**. (cf Freezed, json_serializable, etc.)
When the Dart team was working on a feature called "macros", using code generation was the recommended way to use Riverpod. Unfortunately, those have been cancelled.

While code-generation brings many benefits, it currently is still fairly slow.
The Dart team is working on improving the performance of code generation, but it is unclear when that will be available and how much it will improve.
As such, if you are not already using code generation in your project, it is probably not worth it to start using it just for Riverpod.

At the same time, many applications already use code generation with packages such as [Freezed](https://pub.dev/packages/freezed) or [json_serializable](https://pub.dev/packages/json_serializable).
In that case, your project probably is already set up for code generation, and using Riverpod should be simple.

## What are the benefits of using code generation?

You may be wondering: "If code generation is optional in Riverpod, why use it?"

As always with packages: To make your life easier.
This includes but is not limited to:

*   Better syntax, more readable/flexible, and with a reduced learning curve.
    *   No need to worry about the type of provider. Write your logic, and Riverpod will pick the most suitable provider for you.
    *   The syntax no longer looks like we're defining a "dirty global variable". Instead we are defining a custom function/class.
    *   Passing parameters to providers is now unrestricted. Instead of being limited to using [Family](/docs/concepts2/family) and passing a single positional parameter, you can now pass any parameter. This includes named parameters, optional ones, and even default values.
*   **Stateful hot-reload** of the code written in Riverpod.
*   Better debugging, through the generation of extra metadata that the debugger then picks up.

## The Syntax

### Defining a provider:

When defining a provider using code generation, it is helpful to keep in mind the following points:

*   Providers can be defined either as an annotated **function** or as an annotated **class**. They are pretty much the same, but Class-based provider has the advantage of including public methods that enable external objects to modify the state of the provider (side-effects). Functional providers are syntax sugar for writing a Class-based provider with nothing but a `build` method, and as such cannot be modified by the UI.
*   All Dart **async** primitives (Future, FutureOr, and Stream) are supported.
*   When a function is marked as **async**, the provider automatically handles errors/loading states and exposes an AsyncValue.

| | Functional (Can’t perform side-effects using public methods) | Class-Based (Can perform side-effects using public methods) |
|---|---|---|
| **Sync** | ```dart
@riverpod
String example(Ref ref) {
  return 'foo';
}
``` | ```dart
@riverpod
class Example extends _$Example {
  @override
  String build() {
    return 'foo';
  }

  void doSomething() {}
}
``` |
| **Async** | ```dart
@riverpod
Future<String> example(Ref ref) async {
  return Future.value('foo');
}
``` | ```dart
@riverpod
class Example extends _$Example {
  @override
  Future<String> build() async {
    return Future.value('foo');
  }

  void doSomething() {}
}
``` |
| **Stream** | ```dart
@riverpod
Stream<String> example(Ref ref) async* {
  yield 'foo';
}
``` | ```dart
@riverpod
class Example extends _$Example {
  @override
  Stream<String> build() async* {
    yield 'foo';
  }

  void doSomething() {}
}
``` |

All generated providers (functions and classes) use `.autoDispose` by default, meaning that they will dispose of themselves when there are no listeners attached to them (ref.watch/ref.listen).
This default setting better aligns with Riverpod's philosophy. Initially with the non-code generation variant, autoDispose was off by default to accommodate users migrating from `package:provider`.

If you want to disable autoDispose, you can do so by passing `keepAlive: true` to the annotation.

```dart
// AutoDispose provider (keepAlive is false by default)
@riverpod
String example1(Ref ref) => 'foo';

// Non-autoDispose provider
@Riverpod(keepAlive: true)
String example2(Ref ref) => 'bar';
```

#### Parameters:

When defining functional providers, parameters are directly included in the main function's signature. This is similar to how arguments are passed in normal Dart functions.

Instead, the main function of our provider can accept any number of parameters, including named, optional, or default values.
Do note however that these parameters should still have a consistent `==`.
Meaning either the values should be cached, or the parameters should override `==`.

| | Functional | Class-Based |
|---|---|---|
| **Sync** | ```dart
@riverpod
String example(
  Ref ref,
  int param1, {
  String param2 = 'foo',
}) {
  return 'Hello $param1 $param2';
}
``` | ```dart
@riverpod
class Example extends _$Example {
  @override
  String build(
    int param1, {
    String param2 = 'foo',
  }) {
    return 'Hello $param1 $param2';
  }
}
``` |

The following are the corresponding options for transitioning into code-generation variant:

| Provider | Before | After |
|---|---|---|
| Provider | ```dart
final exampleProvider = Provider.autoDispose<String>((
  ref,
) {
  return 'Hello';
});
``` | ```dart
@riverpod
String example(Ref ref) {
  return 'Hello';
}
``` |
| FutureProvider | ```dart
final exampleProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'Hello';
});
``` | ```dart
@riverpod
Future<String> example(Ref ref) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'Hello';
}
``` |
| StreamProvider | ```dart
final exampleProvider = StreamProvider.autoDispose<String>((
  ref,
) async* {
  await Future<void>.delayed(const Duration(seconds: 1));
  yield 'Hello';
});
``` | ```dart
@riverpod
Stream<String> example(Ref ref) async* {
  await Future<void>.delayed(const Duration(seconds: 1));
  yield 'Hello';
}
``` |
| NotifierProvider | ```dart
final exampleProvider = NotifierProvider.autoDispose<Example, String>(Example.new);

class Example extends Notifier<String> {
  @override
  String build() {
    return 'Hello';
  }

  void doSomething() {}
}
``` | ```dart
@riverpod
class Example extends _$Example {
  @override
  String build() {
    return 'Hello';
  }

  void doSomething() {}
}
``` |
| AsyncNotifierProvider | ```dart
final exampleProvider = AsyncNotifierProvider.autoDispose<Example, String>(Example.new);

class Example extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return 'Hello';
  }

  void doSomething() {}
}
``` | ```dart
@riverpod
class Example extends _$Example {
  @override
  Future<String> build() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return 'Hello';
  }

  void doSomething() {}
}
``` |
| StreamNotifierProvider | ```dart
final exampleProvider = StreamNotifierProvider.autoDispose<Example, String>(Example.new);

class Example extends StreamNotifier<String> {
  @override
  Stream<String> build() async* {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield 'Hello';
  }

  void doSomething() {}
}
``` | ```dart
@riverpod
class Example extends _$Example {
  @override
  Stream<String> build() async* {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield 'Hello';
  }

  void doSomething() {}
}
``` |

