# Offline persistence (experimental) | Riverpod

Offline persistence is the ability to store the state of [Providers](/docs/concepts2/providers) on the user's device, so that it can be accessed even when the user is offline or when the app is restarted.

Riverpod is independent from the underlying database or the protocol used to store the data.
But by default, Riverpod provides [riverpod_sqflite](https://pub.dev/packages/riverpod_sqflite) alongside basic JSON serialization.

> Riverpod's offline persistence is designed to be a simple wrapper around databases. It is not designed to fully replace code for interacting with a database.
>
> You may still need to manually interact with a database for:
> *   Advanced Database migrations
> *   More optimized storage strategies
> *   Unusual use-cases

Offline persistence works using two parts:

1.  [Storage](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/Storage-class.html), an interface to interact with your database.
    This is typically implemented by a package (such as [riverpod_sqflite](https://pub.dev/packages/riverpod_sqflite)).
2.  [AnyNotifier.persist](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/NotifierPersistX/persist.html), a function used inside notifiers to opt-in to persistence.

## Creating a Storage

Before we start persisting notifiers, we need to instantiate an object that implements the [Storage](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/Storage-class.html) interface. This object will be responsible for connecting Riverpod with your database.

You need have to either:

*   Download a package that provides a way to connect Riverpod with your Database of choice.
*   Manually implement [Storage](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/Storage-class.html)

If using SQFlite, you can use [riverpod_sqflite](https://pub.dev/packages/riverpod_sqflite):

```bash
dart pub add riverpod_sqflite sqflite
```

Then, you can create a Storage by instantiating [JsonSqFliteStorage](https://pub.dev/documentation/riverpod_sqflite/latest/riverpod_sqflite/JsonSqFliteStorage-class.html):

**riverpod**
```dart
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';

final storageProvider = FutureProvider<Storage<String, String>>((ref) async {
  // Initialize SQFlite. We should share the Storage instance between providers.
  return JsonSqFliteStorage.open(
    join(await getDatabasesPath(), 'riverpod.db'),
  );
});
```

**riverpod_generator**
```dart
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';

part 'codegen.g.dart';

@riverpod
Future<Storage<String, String>> storage(Ref ref) async {
  // Initialize SQFlite. We should share the Storage instance between providers.
  return JsonSqFliteStorage.open(
    join(await getDatabasesPath(), 'riverpod.db'),
  );
}
```

## Persisting the state of a provider

Once we've created a [Storage](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/Storage-class.html), we can start persisting the state of providers.

> Currently, only "Notifiers" can be persisted. See [Providers](/docs/concepts2/providers) for more information about them.

To persist the state of a notifier, you will typically need to call [AnyNotifier.persist](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/NotifierPersistX/persist.html) inside the `build` method of your notifier.

**riverpod**
```dart
class Todo {
  Todo({
    required this.id,
    required this.label,
    required this.completed,
  });

  factory Todo.fromJson(Map<String, Object?> json) => Todo(
        id: json['id']! as String,
        label: json['label']! as String,
        completed: json['completed']! as bool,
      );

  final String id;
  final String label;
  final bool completed;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'completed': completed,
      };
}

class TodoList extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    final storage = await ref.watch(storageProvider.future);
    // The "key" is how the data will be stored in the database.
    // Here, we use "todos" as the key.
    // The default cache duration is 2 days.
    return persist('todos', storage, fromJson: Todo.fromJson);
  }

  void addTodo(Todo todo) {
    // TODO: Add todo and save it to the database
  }
}
```

**riverpod_generator**
```dart
// Using freezed or json_serializable to generate from/toJson for your objects
@freezed
abstract class Todo with _$Todo {
  factory Todo({
    required String id,
    required String label,
    required bool completed,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) =>
      _$TodoFromJson(json);
}

@Riverpod(keepAlive: true)
class TodoList extends _$TodoList {
  @override
  Future<List<Todo>> build() async {
    final storage = await ref.watch(storageProvider.future);
    // The "key" is how the data will be stored in the database.
    // Here, we use "todos" as the key.
    // The default cache duration is 2 days.
    return persist('todos', storage, fromJson: Todo.fromJson);
  }

  void addTodo(Todo todo) {
    // TODO: Add todo and save it to the database
  }
}
```

`persist` takes three parameters:

*   `key`: A `String` representing the unique ID of the data in the database.
    That key is there to enable your database to know where to store the state of a provider in the Database.
    Depending on the database, this key may be a unique row ID.

    When specifying `key`, it is critical to ensure that:

    *   The key is unique across all providers that you persist.
        Failing to do so could cause data corruption, as two providers could be trying to write to the same row in the database. If Riverpod detects two providers using the same key, an assertion will be thrown.
    *   The key is stable across app restarts.
        If the key changes, Riverpod will not be able to restore the state of the provider when the app is restarted, and the provider will be initialized as if it was never persisted
    *   The key needs to include any parameter that the provider takes.
        When using "families" (cf [Family](/docs/concepts2/family)), the key needs to include the family parameter.

*   `storage`: The [Storage](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/Storage-class.html) instance to use.
*   `fromJson`: A callback used to deserialize the data from JSON.

## Changing the cache duration

By default, state is only cached for 2 days. This default ensures that no leak happens and deleted providers stay in the database indefinitely

This is generally safe, as Riverpod is designed to be used primarily as a cache for IO operations (network requests, database queries, etc).
But such default will not be suitable for all use-cases, such as if you want to store user preferences.

To change this default, specify `options` like so:

**riverpod**
```dart
@override
Future<List<Todo>> build() async {
  final storage = await ref.watch(storageProvider.future);
  return persist(
    'todos',
    storage,
    fromJson: Todo.fromJson,
    options: const PersistOptions(maxAge: Duration(days: 365)),
  );
}
```

**riverpod_generator**
```dart
@override
Future<List<Todo>> build() async {
  final storage = await ref.watch(storageProvider.future);
  return persist(
    'todos',
    storage,
    fromJson: Todo.fromJson,
    options: const PersistOptions(maxAge: Duration(days: 365)),
  );
}
```

> `PersistOptions` also includes an `onDataRemoved` property. This can be useful for performing custom cleanup when the persisted state is removed from the database.

## Manually deleting persisted state

If you want to manually delete the persisted state, you can use `storage.delete('your-key')`.

```dart
final storage = await ref.watch(storageProvider.future);
await storage.delete('todos');
```

This is generally not needed, as the state is automatically removed from the database after `maxAge` expires.
However, you may need to manually delete the persisted state from the database if you ever delete the provider.

For this, refer to your database's documentation.

## Using "destroy key" for simple data-migration

A common challenge when persisting data is handling when the data structure changes.
If you change how an object is serialized, you may need to migrate the data stored in the database.

While Riverpod does not provide a way to do proper data migration, it does provide a way to easily replace the old persisted state with a brand new one: Destroy keys.

**riverpod**
```dart
class TodoList extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    final storage = await ref.watch(storageProvider.future);
    return persist(
      'todos',
      storage,
      fromJson: Todo.fromJson,
      options: const PersistOptions(destroyKey: 'v2'),
    );
  }
}
```

**riverpod_generator**
```dart
@Riverpod(keepAlive: true)
class TodoList extends _$TodoList {
  @override
  Future<List<Todo>> build() async {
    final storage = await ref.watch(storageProvider.future);
    return persist(
      'todos',
      storage,
      fromJson: Todo.fromJson,
      options: const PersistOptions(destroyKey: 'v2'),
    );
  }
}
```

`destroyKey` is a simple string that will be stored alongside your data.
If the `destroyKey` changes, it means that the old persisted state should be discarded. When a new version of the application is released with a different destroyKey, the old persisted state will be discarded, and the provider will be initialized as if it was never persisted.

## Waiting for persistence decoding

Until now, we've never waited for [AnyNotifier.persist](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/NotifierPersistX/persist.html) to complete.
This is voluntary, as this allows the provider to start its network requests as soon as possible.
However, it means that the provider cannot easily access the persisted state right after calling `persist`.

In some cases, instead of initializing the provider with a network request, you may want to initialize it with the persisted state.

In that case, you can await the result of `persist` as follows:

```dart
await persist(...).future;
```

This enables accessing the persisted state within `build` using `this.state`:

```dart
@override
Future<List<Todo>> build() async {
  final storage = await ref.watch(storageProvider.future);
  await persist(
    'todos',
    storage,
    fromJson: Todo.fromJson,
  ).future;
  return this.state; // The state is now available
}
```

## Testing persisted providers

When testing providers that use offline persistence, there is one particular concern:
In particular, unit and widget tests will not have access to a device, and thus cannot use a database.

For this reason, Riverpod provides a way to use an in-memory database using [Storage.inMemory](https://pub.dev/documentation/hooks_riverpod/latest/experimental_persist/Storage/Storage.inMemory.html).
To have your test use this in-memory database, you can use [Provider overrides](/docs/concepts2/overrides):

```dart
testWidgets('Widget test example', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(Storage.inMemory()),
      ],
      child: const MyApp(),
    ),
  );
});
```
