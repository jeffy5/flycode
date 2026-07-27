---
name: riverpod
description: Comprehensive guidance for using Riverpod for state management in Flutter and Dart applications, including best practices, common pitfalls, and migration strategies.
---

# Riverpod Skill

This skill provides comprehensive guidance for using Riverpod for state management in Flutter and Dart applications. It covers installation, core concepts, best practices, and common issues, ensuring efficient and maintainable state management.

## Correct Riverpod Usage

### Installation
To get started with Riverpod, add the necessary packages to your `pubspec.yaml` file.

**For Flutter applications:**
```yaml
dependencies:
  flutter_riverpod: ^latest_version # For Flutter integration
  riverpod: ^latest_version        # Core Riverpod package
```

**For Dart-only applications:**
```yaml
dependencies:
  riverpod: ^latest_version        # Core Riverpod package
```

**For code generation (recommended for larger projects):**
```yaml
dependencies:
  riverpod_annotation: ^latest_version
dev_dependencies:
  build_runner: ^latest_version
  riverpod_generator: ^latest_version
```
After adding dependencies, run `flutter pub get` or `dart pub get`.

### Enabling Riverpod Lint
It is highly recommended to enable `riverpod_lint` for better code quality and to catch common mistakes early. Create an `analysis_options.yaml` file next to your `pubspec.yaml` and add:

```yaml
plugins:
  riverpod_lint: <latest version from https://pub.dev/packages/riverpod_lint>
```

### Basic "Hello World" Example

**Flutter (with `flutter_riverpod`):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final helloWorldProvider = Provider((_) => 'Hello world');

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Example')),
        body: Center(
          child: Consumer(builder: (context, ref, child) {
            final value = ref.watch(helloWorldProvider);
            return Text(value);
          }),
        ),
      ),
    );
  }
}
```

**Dart-only (with `riverpod`):**
```dart
import 'package:riverpod/riverpod.dart';

final helloWorldProvider = Provider((_) => 'Hello world');

void main() {
  final container = ProviderContainer();
  final value = container.read(helloWorldProvider);
  print(value); // Hello world
  container.dispose();
}
```

### Key Concepts: Providers
Providers are the central feature of Riverpod, acting as "memoized functions" that cache values and provide powerful features like automatic disposal, data-binding, and error handling.

**Provider Variants:**
| | Synchronous | Future | Stream |
|---|---|---|---|
| Unmodifiable | `Provider` | `FutureProvider` | `StreamProvider` |
| Modifiable | `NotifierProvider` | `AsyncNotifierProvider` | `StreamNotifierProvider` |

*   **Synchronous** vs **Future** vs **Stream**: Choose based on the return type of your data (immediate value, `Future`, or `Stream`).
*   **Unmodifiable** vs **Modifiable**: Unmodifiable providers provide a read-only state. Modifiable (Notifier) providers allow external modification of their state.

**Creating a Provider:**
Providers are top-level declarations.

*   **Unmodifiable (functional)**
    ```dart
    final name = SomeProvider.someModifier<Result>((ref) {
      // <your logic here>
    });
    ```
    -   `name`: The final, global provider variable used to interact with the provider.
    -   `SomeProvider`: The type of provider (e.g., `Provider`, `FutureProvider`, `StreamProvider`).
    -   `someModifier`: Optional modifiers like `.autoDispose` or `.family` to tweak behavior.
    -   `ref`: An object to interact with other providers.
    -   `your logic here`: The function that defines the provider's value.

*   **Modifiable (Notifier)**
    ```dart
    final name = SomeNotifierProvider.someModifier<MyNotifier, Result>(MyNotifier.new);

    class MyNotifier extends SomeNotifier<Result> {
      @override
      Result build() {
        // <your logic here>
      }
      // <your methods here>
    }
    ```
    -   `name`: The final, global provider variable.
    -   `SomeNotifierProvider`: The type of notifier provider (e.g., `NotifierProvider`, `AsyncNotifierProvider`, `StreamNotifierProvider`).
    -   `someModifier`: Optional modifiers like `.autoDispose` or `.family`.
    -   `MyNotifier.new`: Constructor tear-off for the notifier class.
    -   `MyNotifier`: The notifier class that extends `SomeNotifier<Result>`.
    -   `build()`: Overridden method containing the provider's initialization logic.

For more detailed information on providers, see [references/providers.md](references/providers.md).

## Quickstart for Provider Users

If you are familiar with the `Provider` package, migrating to Riverpod can be incremental.

*   **Start with `ChangeNotifierProvider`**: You can initially use Riverpod's `ChangeNotifierProvider` to wrap your existing `ChangeNotifier`s. This is a gentle way to introduce Riverpod without immediately rewriting everything.
*   **Start with "leaves"**: Begin by migrating providers that have no dependencies (leaves in your dependency tree).
*   **Riverpod and Provider can coexist**: You can use both packages simultaneously, leveraging import aliases to avoid conflicts.
*   **Migrate one Provider at a time**: Don't try to migrate your entire application at once. Tackle one provider at a time.
*   **Migrating `ProxyProvider`s**: In Riverpod, providers are composable by default using `ref.watch`, simplifying `ProxyProvider` migrations.
*   **Eager Initialization**: Providers are lazy by default. For eager initialization, read your provider in your startup phase.
*   **Code Generation**: Recommended for future-proof Riverpod usage. While `ChangeNotifierProvider` doesn't directly support `@riverpod` annotations, workarounds exist.

For full quickstart details, see [references/quickstart.md](references/quickstart.md).

## Frequently Asked Questions (FAQ)
For answers to common questions about Riverpod, refer to [references/faq.md](references/faq.md).

## DO/DON'T
For a list of best practices and common pitfalls to avoid when using Riverpod, refer to [references/do_dont.md](references/do_dont.md).

## Concepts
For in-depth understanding of Riverpod's core concepts, refer to the following:
*   [Providers](references/providers.md)
*   [Consumers](references/consumers.md)
*   [ProviderContainers/ProviderScopes](references/containers.md)
*   [Refs](references/refs.md)
*   [Automatic disposal](references/auto_dispose.md)
*   [Family](references/family.md)
*   [Mutations (experimental)](references/mutations.md)
*   [Offline persistence (experimental)](references/offline.md)
*   [Automatic retry](references/retry.md)
*   [ProviderObservers](references/observers.md)
*   [Provider overrides](references/overrides.md)
*   [Scoping providers](references/scoping.md)
*   [About code generation](references/about_code_generation.md)
*   [About hooks](references/about_hooks.md)

## Guides
For practical guides and how-to's, refer to the following:
*   [Testing your providers](references/testing.md)
*   [How to reduce provider/widget rebuilds](references/select.md)
*   [How to eagerly initialize providers](references/eager_initialization.md)
*   [Implementing pull-to-refresh](references/pull_to_refresh.md)
*   [How to debounce/cancel network requests](references/cancel.md)
