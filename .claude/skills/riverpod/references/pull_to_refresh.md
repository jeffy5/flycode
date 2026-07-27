# Implementing pull-to-refresh | Riverpod

Riverpod natively supports pull-to-refresh thanks to its declarative nature.

In general, pull-to-refreshes can be complex due as there are multiple problems to solve:

*   Upon first entering a page, we want to show a spinner.
    But during refresh, we want to show the refresh indicator instead.
    We shouldn't show both the refresh indicator *and* spinner.
*   While a refresh is pending, we want to show the previous data/error.
*   We need to show the refresh indicator for as long as the refresh is happening.

Let's see how to solve this using Riverpod.
For this, we will make a simple example which recommends a random activity to users.
And doing a pull-to-refresh will trigger a new suggestion:

![A gif of the previously described application working](/img/how_to/pull_to_refresh/app.gif)

## Making a bare-bones application.

Before implement a pull-to-refresh, we first need something to refresh.
We can make a simple application which uses [Bored API](https://www.boredapi.com/) to suggests a random activity to users.

First, let's define an `Activity` class:

**riverpod**
```dart
class Activity {
  Activity({
    required this.activity,
    required this.type,
    required this.participants,
    required this.price,
  });

  factory Activity.fromJson(Map<Object?, Object?> json) {
    return Activity(
      activity: json['activity']! as String,
      type: json['type']! as String,
      participants: json['participants']! as int,
      price: json['price']! as double,
    );
  }

  final String activity;
  final String type;
  final int participants;
  final double price;
}
```

**riverpod_generator**
```dart
@freezed
sealed class Activity with _$Activity {
  factory Activity({
    required String activity,
    required String type,
    required int participants,
    required double price,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
```

That class will be responsible for representing a suggested activity in a type-safe manner, and handle JSON encoding/decoding.
Using Freezed/json_serializable is not required, but it is recommended.

Now, we'll want to define a provider making a HTTP GET request to fetch a single activity:

**riverpod**
```dart
final activityProvider = FutureProvider.autoDispose<Activity>((
  ref,
) async {
  final response = await http.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
});
```

**riverpod_generator**
```dart
@riverpod
Future<Activity> activity(Ref ref) async {
  final response = await http.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
}
```

Finally, let's implement our UI. For now, we will not handle the loading/error state, and simply display the activity when available:

```dart
class ActivityView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('BoredApp')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(activityProvider.future),
        child: ListView(
          children: [
            if (activity.hasValue) Text(activity.value!.activity),
          ],
        ),
      ),
    );
  }
}
```

## Handling loading/error states.

In the previous section, we did not handle the loading/error states.
Instead the data magically pops up when the loading/refresh is done.

Let's change this by gracefully handling those states. There are two cases:

*   During the initial load, we want to show a full-screen spinner.
*   During a refresh, we want to show the refresh indicator and the previous data/error.

Fortunately, when listening to an asynchronous provider in Riverpod, Riverpod gives us an `AsyncValue`, which offers everything we need.

That `AsyncValue` can then be combined with Dart 3.0's pattern matching as follows:

```dart
class ActivityView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('BoredApp')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(activityProvider.future),
        child: ListView(
          children: [
            switch (activity) {
              AsyncData(:final value) => Text(value.activity),
              AsyncError(:final error) => Text('Error: $error'),
              _ => const CircularProgressIndicator(),
            },
          ],
        ),
      ),
    );
  }
}
```

> `AsyncValue` also exposes properties such as `isLoading` and `hasError`.
> Those can be useful when we don't want to change the displayed widget but only change its state, such as displaying a disabled button if in error/loading state.
>
> Riverpod 3.0 will change this to have `value` behave like `valueOrNull`.
> But for now, let's stick to `valueOrNull`.

> Notice the usage of the `:final valueOrNull?` syntax in our pattern matching.
> This syntax can be used only because `activityProvider` returns a non-nullable `Activity`.
>
> If your data can be `null`, you can instead use `AsyncValue(hasData: true, :final valueOrNull)`.
> This will correctly handle cases where the data is `null`, at the cost of a few extra characters.

## Wrapping up: full application

Here is the combined source of everything we've covered so far:

**riverpod**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class Activity {
  Activity({
    required this.activity,
    required this.type,
    required this.participants,
    required this.price,
  });

  factory Activity.fromJson(Map<Object?, Object?> json) {
    return Activity(
      activity: json['activity']! as String,
      type: json['type']! as String,
      participants: json['participants']! as int,
      price: json['price']! as double,
    );
  }

  final String activity;
  final String type;
  final int participants;
  final double price;
}

final activityProvider = FutureProvider.autoDispose<Activity>((
  ref,
) async {
  final response = await http.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
});

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('BoredApp')),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(activityProvider.future),
          child: ListView(
            children: [
              // Display the value based on the current state
              switch (ref.watch(activityProvider)) {
                AsyncData(:final value) => Text(value.activity),
                AsyncError(:final error) => Text('Error: $error'),
                _ => const CircularProgressIndicator(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
```

**riverpod_generator**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;

part 'main.g.dart';
part 'main.freezed.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

@freezed
sealed class Activity with _$Activity {
  factory Activity({
    required String activity,
    required String type,
    required int participants,
    required double price,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}

@riverpod
Future<Activity> activity(Ref ref) async {
  final response = await http.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('BoredApp')),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(activityProvider.future),
          child: ListView(
            children: [
              // Display the value based on the current state
              switch (ref.watch(activityProvider)) {
                AsyncData(:final value) => Text(value.activity),
                AsyncError(:final error) => Text('Error: $error'),
                _ => const CircularProgressIndicator(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
```