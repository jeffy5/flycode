# How to reduce provider/widget rebuilds | Riverpod

With everything we've seen so far, we can already build a fully functional application. However, you may have questions regarding performance.

In this page, we will cover a few tips and tricks to possibly optimize your code.

> Before doing any optimization, make sure to benchmark your application.
> The added complexity of the optimizations may not be worth minor gains.

## Filtering widget/provider rebuild using "select".

You may have noticed that, by default, using `ref.watch` causes consumers/providers to rebuild whenever *any* of the properties of an object changes.
For instance, watching a `User` and only using its "name" will still cause the consumer to rebuild if the "age" changes.

But in case you have a consumer using only a subset of the properties, you want to avoid rebuilding the widget when the other properties change.

This can be achieved by using the `select` functionality of providers.
When doing so, `ref.watch` will no-longer return the full object, but rather the selected properties.
And your consumers/providers will now rebuild only if those selected properties change.

**riverpod**
```dart
class User {
  late String firstName, lastName;
}

final provider = Provider(
  (ref) => User()
    ..firstName = 'John'
    ..lastName = 'Doe',
);

class ConsumerExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instead of writing:
    // String name = ref.watch(provider).firstName!;
    // We can write:
    String name = ref.watch(provider.select((it) => it.firstName));
    // This will cause the widget to only listen to changes on "firstName".

    return Text('Hello $name');
  }
}
```

**riverpod_generator**
```dart
class User {
  late String firstName, lastName;
}

@riverpod
User example(Ref ref) => User()
  ..firstName = 'John'
  ..lastName = 'Doe';

class ConsumerExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instead of writing:
    // String name = ref.watch(provider).firstName!;
    // We can write:
    String name = ref.watch(exampleProvider.select((it) => it.firstName));
    // This will cause the widget to only listen to changes on "firstName".

    return Text('Hello $name');
  }
}
```

> It is possible to call `select` as many times as you wish.
> You are free to call it once per property you desire.

> The selected properties are expected to be immutable.
> Returning a `List` and then mutating that list will not trigger a rebuild.

> Using `select` slightly slows down individual read operations and increases the complexity of your code by a tiny bit.
> It may not be worth using it if those "other properties" rarely change.

### Selecting asynchronous properties

In case you are trying to optimize a provider listening to another provider, chances are that other provider is asynchronous.

Normally, you would `ref.watch(anotherProvider.future)` to get the value.
The issue is, `select` will apply on an `AsyncValue` – which is not something you can await.

For this purpose, you can instead use `selectAsync`. It is unique to asynchronous code, and enables performing a `select` operation on the data emitted by a provider.
Its usage is similar to that of `select`, but returns a `Future` instead:

**riverpod**
```dart
final provider = FutureProvider((ref) async {
  // Wait for a user to be available, and listen to only the "firstName" property
  final name = await ref.watch(userProvider.selectAsync((user) => user.firstName));
  return 'Hello $name';
});
```

**riverpod_generator**
```dart
@riverpod
Future<String> example(Ref ref) async {
  // Wait for a user to be available, and listen to only the "firstName" property
  final name = await ref.watch(userProvider.selectAsync((user) => user.firstName));
  return 'Hello $name';
}
```