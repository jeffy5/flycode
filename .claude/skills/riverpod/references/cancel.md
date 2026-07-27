# How to debounce/cancel network requests | Riverpod

As applications grow in complexity, it's common to have multiple network requests in flight at the same time. For example, a user might be typing in a search box and triggering a new request for each keystroke. If the user types quickly, the application might have many requests in flight at the same time.

Alternatively, a user might trigger a request, then navigate to a different page before the request completes. In this case, the application might have a request in flight that is no longer needed.

To optimize performance in those situations, there are a few techniques you can use:

*   "Debouncing" requests. This means that you wait until the user has stopped typing for a certain amount of time before sending the request. This ensures that you only send one request for a given input, even if the user types quickly.
*   "Cancelling" requests. This means that you cancel a request if the user navigates away from the page before the request completes. This ensures that you don't waste time processing a response that the user will never see.

In Riverpod, both of these techniques can be implemented in a similar way.
The key is to use `ref.onDispose` combined with "automatic disposal" or `ref.watch` to achieve the desired behavior.

To showcase this, we will make a simple application with two pages:

*   A home screen, with a button which opens a new page
*   A detail page, which displays a random activity from the [Bored API](https://www.boredapi.com/), with the ability to refresh the activity.
    See [Implementing pull-to-refresh](/docs/how_to/pull_to_refresh) for information on how to implement pull-to-refresh.

We will then implement the following behaviors:

*   If the user opens the detail page and then navigates back immediately, we will cancel the request for the activity.
*   If the user refreshes the activity multiple times in a row, we will debounce the requests so that we only send one request after the user stops refreshing.

## The application

![Gif showcasing the application, opening the detail page and refreshing the activity.](/img/how_to/cancel/app.gif)

First, let's create the application, without any debouncing or cancelling.
We won't use anything fancy here, and stick to a plain `FloatingActionButton` with a `Navigator.push` to open the detail page.

First, let's start with defining our home screen. As usual, let's not forget to specify a `ProviderScope` at the root of our application.

**lib/src/main.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/detail-page': (_) => const DetailPageView(),
      },
      home: const ActivityView(),
    );
  }
}

class ActivityView extends ConsumerWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home screen')),
      body: const Center(
        child: Text('Click the button to open the detail page'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/detail-page'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Then, let's define our detail page.
To fetch the activity and implement pull-to-refresh, refer to the [Implementing pull-to-refresh](/docs/how_to/pull_to_refresh) case study.

**lib/src/detail_screen.dart**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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

class DetailPageView extends ConsumerWidget {
  const DetailPageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail page')),
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

## Cancelling network requests

One common use-case for cancelling network requests is when a user navigates away from the page. For this to work, it is important that the automatic disposal of providers is enabled.

The exact code needed to cancel the request will depend on the HTTP client.
In this example, we will use `package:http`, but the same principle applies to other clients.

The key here is that `ref.onDispose` will be called when the user navigates away.
That is because our provider is no-longer used, and therefore disposed thanks to automatic disposal.
We can therefore use this callback to cancel the request. When using `package:http`, this can be done by closing our HTTP client.

**riverpod**
```dart
final activityProvider = FutureProvider.autoDispose<Activity>((
  ref,
) async {
  // Keep a reference to the `HttpClient` to be able to close it later.
  final client = http.Client();
  ref.onDispose(client.close);

  final response = await client.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
});
```

**riverpod_generator**
```dart
@riverpod
Future<Activity> activity(Ref ref) async {
  // Keep a reference to the `HttpClient` to be able to close it later.
  final client = http.Client();
  ref.onDispose(client.close);

  final response = await client.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
}
```

## Debouncing network requests

At the moment, if the user refreshes the activity multiple times in a row, we will send a request for each refresh.

Technically speaking, now that we have implemented cancellation, this is not a problem. If the user refreshes the activity multiple times in a row, the previous request will be cancelled, when a new request is made.

However, this is not ideal. We are still sending multiple requests, and wasting bandwidth and server resources.
What we could instead do is delay our requests until the user stops refreshing the activity for a fixed amount of time.

The logic here is very similar to the cancellation logic. We will again use `ref.onDispose`. However, the idea here is that instead of closing an HTTP client, we will rely on `onDispose` to abort the request before it starts.
We will then arbitrarily wait for 500ms before sending the request.
Then, if the user refreshes the activity again before the 500ms have elapsed, `onDispose` will be invoked, aborting the request.

> To abort requests, a common practice is to voluntarily throw.
> It is safe to throw inside providers after the provider has been disposed.
> The exception will naturally be caught by Riverpod and be ignored.

**riverpod**
```dart
final activityProvider = FutureProvider.autoDispose<Activity>((
  ref,
) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  // Debounce the request.
  await Future<void>.delayed(const Duration(milliseconds: 500));
  if (cancelToken.isCancelled) throw Exception('Cancelled');

  final response = await http.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
});
```

**riverpod_generator**
```dart
@riverpod
Future<Activity> activity(Ref ref) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  // Debounce the request.
  await Future<void>.delayed(const Duration(milliseconds: 500));
  if (cancelToken.isCancelled) throw Exception('Cancelled');

  final response = await http.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
}
```

## Going further: creating a reusable debounce + cancel utility

Our current implementation of debounce + cancel works. But currently, if we want to do another request, we need to copy-paste the same logic in multiple places. This is not ideal.

However, we can go further and implement a reusable utility to do both at once.

The idea here is to implement an extension method on `Ref` that will handle both cancellation and debouncing in a single method.

```dart
extension DebounceAndCancelExtension on Ref {
  /// Wait for [duration] (defaults to 500ms), and then return a [http.Client]
  /// which can be used to make a request.
  ///
  /// That client will automatically be closed when the provider is disposed.
  Future<http.Client> getDebouncedHttpClient([Duration duration = const Duration(milliseconds: 500)]) async {
    final cancelToken = CancelToken();
    onDispose(cancelToken.cancel);

    // Debounce the request.
    await Future<void>.delayed(duration);
    if (cancelToken.isCancelled) throw Exception('Cancelled');

    final client = http.Client();
    onDispose(client.close);
    return client;
  }
}
```

Then, our activity provider can be rewritten as:

**riverpod**
```dart
final activityProvider = FutureProvider.autoDispose<Activity>((
  ref,
) async {
  final client = await ref.getDebouncedHttpClient();
  final response = await client.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
});
```

**riverpod_generator**
```dart
@riverpod
Future<Activity> activity(Ref ref) async {
  final client = await ref.getDebouncedHttpClient();
  final response = await client.get(Uri.https('www.boredapi.com', '/api/activity'));
  return Activity.fromJson(json.decode(response.body));
}
```