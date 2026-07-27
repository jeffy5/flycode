# Getting started | Riverpod

## Try Riverpod online

To get a feel of Riverpod, try it online on [Dartpad](https://dartpad.dev/?null_safety=true&id=ef06ab3ce0b822e6cc5db0575248e6e2) or on [Zapp](https://zapp.run/new).

## Installing the package

Riverpod comes as a main "riverpod" package that’s self-sufficient, complemented by optional packages for using code generation ([About code generation](/docs/concepts/about_code_generation)) and hooks ([About hooks](/docs/concepts/about_hooks)).

**Caution:**
For the sake of being compatible with the latest `json_serializable` package, some Riverpod packages are currently only compatible with Flutter's beta channel or later. If `pub get` is failing due to version solving issues, consider switching to the beta channel by running:

```bash
flutter channel beta
```

Or consider downgrading Riverpod to `<=3.1.0`.

Once you know what package(s) you want to install, proceed to add the dependency to your app in a single line like this:

**Flutter**
**riverpod**
```yaml
dependencies:
  riverpod: ^latest_version
```

**riverpod_generator**
```yaml
dependencies:
  riverpod_annotation: ^latest_version
dev_dependencies:
  build_runner: ^latest_version
  riverpod_generator: ^latest_version
```

**Dart only**
**riverpod**
```yaml
dependencies:
  riverpod: ^latest_version
```

**riverpod_generator**
```yaml
dependencies:
  riverpod_annotation: ^latest_version
dev_dependencies:
  build_runner: ^latest_version
  riverpod_generator: ^latest_version
```

### Enabling `riverpod_lint`/`custom_lint`

`riverpod_lint` is a package that provides lint rules to help you write better code, and provide custom refactoring options.

`riverpod_lint` is implemented using `analysis_server_plugin`. As such, it is installed through `analysis_options.yaml`

Long story short, create an `analysis_options.yaml` next to your `pubspec.yaml` and add:

**analysis_options.yaml**
```yaml
plugins:
  riverpod_lint: <latest version from https://pub.dev/packages/riverpod_lint>
```

To see the full list of warnings and refactorings, head to the [riverpod_lint](https://pub.dev/packages/riverpod_lint) page.

## Usage example: Hello world

Now that we have installed [Riverpod](https://github.com/rrousselgit/riverpod), we can start using it.

The following snippets showcase how to use our new dependency to make a "Hello world":

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
This will render "Hello world" on your device.

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
This will print "Hello world" in the console.

## Going further: Installing code snippets

If you are using `Flutter` and `VS Code`, consider using [Flutter Riverpod Snippets](https://marketplace.visualstudio.com/items?itemName=robert-brunhage.flutter-riverpod-snippets)

If you are using `Flutter` and `Android Studio` or `IntelliJ`, consider using [Flutter Riverpod Snippets](https://plugins.jetbrains.com/plugin/14641-flutter-riverpod-snippets)