# Testing your providers | Riverpod

A core part of the Riverpod API is the ability to test your providers in isolation.

For a proper test suite, there are a few challenges to overcome:

*   Tests should not share state. This means that new tests should not be affected by the previous tests.
*   Tests should give us the ability to mock certain functionalities to achieve the desired state.
*   The test environment should be as close as possible to the real environment.

Fortunately, Riverpod makes it easy to achieve all of these goals.

## Setting up a test

When defining a test with Riverpod, there are two main scenarios:

*   Unit tests, usually with no Flutter dependency.
    This can be useful for testing the behavior of a provider in isolation.
*   Widget tests, usually with a Flutter dependency.
    This can be useful for testing the behavior of a widget that uses a provider.

### Unit tests

Unit tests are defined using the `test` function from [package:test](https://pub.dev/packages/test).

The main difference with any other test is that we will want to create a `ProviderContainer` object. This object will enable our test to interact with providers.

A typical test using `ProviderContainer` will look like:

```dart
void main() {
  test('Some description', () {
    // Create a ProviderContainer for this test.
    // DO NOT share ProviderContainers between tests.
    final container = ProviderContainer.test();

    // TODO: use the container to test your application.
    expect(
      container.read(provider),
      equals('some value'),
    );
  });
}
```

Now that we have a ProviderContainer, we can use it to read providers using:

*   `container.read`, to read the current value of a provider.
*   `container.listen`, to listen to a provider and be notified of changes.

> Be careful when using `container.read` when providers are automatically disposed.
> If your provider is not listened to, chances are that its state will get destroyed in the middle of your test.
>
> In that case, consider using `container.listen`.
> Its return value enables reading the current value of provider anyway, but will also ensure that the provider is not disposed in the middle of your test:
>
> ```dart
> final subscription = container.listen<String>(
>   provider,
>   (previous, next) {},
> );
>
> expect(
>   // Equivalent to `container.read(provider)`
>   // But the provider will not be disposed unless "subscription" is disposed.
>   subscription.read(),
>   'Some value',
> );
> ```

### Widget tests

Widget tests are defined using the `testWidgets` function from [package:flutter_test](https://pub.dev/packages/flutter_test).

In this case, the main difference with usual Widget tests is that we must add a `ProviderScope` widget at the root of `tester.pumpWidget`:

```dart
void main() {
  testWidgets('Some description', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: YourWidgetYouWantToTest()),
    );
  });
}
```

This is similar to what we do when we enable Riverpod in our Flutter app.

Then, we can use `tester` to interact with our widget.
Alternatively if you want to interact with providers, you can obtain a `ProviderContainer`.
One can be obtained using `tester.container()`.
By using `tester`, we can therefore write the following:

```dart
final container = tester.container();
```

We can then use it to read providers. Here's a full example:

```dart
void main() {
  testWidgets('Some description', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: YourWidgetYouWantToTest()),
    );

    final container = tester.container();

    // TODO interact with your providers
    expect(
      container.read(provider),
      'some value',
    );
  });
}
```

## Mocking providers

So far, we've seen how to set up a test and basic interactions with providers.
However, in some cases, we may want to mock a provider.

The cool part: All providers can be mocked by default, without any additional setup.
This is possible by specifying the `overrides` parameter on either `ProviderScope` or `ProviderContainer`.

Consider the following provider:

**riverpod**
```dart
// An eagerly initialized provider.
final exampleProvider = FutureProvider<String>(
  (ref) async => 'Hello',
);
```

**riverpod_generator**
```dart
@riverpod
Future<String> example(Ref ref) async => 'Hello';
```

To mock this provider, we can do:

```dart
void main() {
  test('Example', () {
    final container = ProviderContainer(
      overrides: [
        exampleProvider.overrideWithValue(AsyncData('Hello from mock')),
      ],
    );

    expect(container.read(exampleProvider), AsyncData('Hello from mock'));
  });
}
```

This is a simple example, but it shows how easy it is to mock providers in Riverpod.

## Mocking notifiers

Consider the following provider:

**riverpod**
```dart
final myNotifierProvider = NotifierProvider<MyNotifier, int>(MyNotifier.new);

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
```

**riverpod_generator**
```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  int build() => 0;

  void increment() => state++;
}
```

Mocking notifiers can be a bit more tricky, as notifiers cannot be instantiated on their own, and only work when used as part of a Provider.

Instead, you should likely introduce a level of abstraction in the logic of your Notifier, such that you can mock that abstraction.
For instance, rather than mocking a Notifier, you could mock a "repository" that the Notifier uses to fetch data from.

If you insist on mocking a Notifier, there is a special consideration to create such a mock: Your mock must subclass the original Notifier base class: You cannot "implement" Notifier, as this would break the interface.

As such, when mocking a Notifier, instead of writing the following mockito code:

```dart
class MyNotifierMock with Mock implements MyNotifier {}
```

You should instead write:

**riverpod**
```dart
class MyNotifierMock extends MyNotifier implements Mock {
  MyNotifierMock() : super();

  @override
  int build() => 0;
}
```

**riverpod_generator**
```dart
class MyNotifierMock extends _$MyNotifier implements Mock {
  @override
  int build() => 0;
}
```

> When using code-generation, this mock should be placed in the same file as the Notifier you are mocking.
> Otherwise you would not have access to the `_$MyNotifier` class.

Then, to use your notifier you could do:

```dart
void main() {
  test('Some description', () {
    final container = ProviderContainer(
      overrides: [
        myNotifierProvider.overrideWith((ref) => MyNotifierMock()),
      ],
    );

    expect(container.read(myNotifierProvider), 0);
  });
}
```