# About hooks | Riverpod

This page explains what hooks are and how they are related to Riverpod.

"Hooks" are utilities common from a separate package, independent from Riverpod: [flutter_hooks](https://github.com/rrousselGit/flutter_hooks).
Although [flutter_hooks](https://github.com/rrousselGit/flutter_hooks) is a completely separate package and does not have anything to do with Riverpod (at least directly), it is common to pair Riverpod and [flutter_hooks](https://github.com/rrousselGit/flutter_hooks) together.

## Should you use hooks?

Hooks are a powerful tool, but they are not for everyone.
If you are a newcomer to Riverpod, **avoid using hooks**.

Although useful, hooks are not necessary for Riverpod.
You shouldn't start using hooks because of Riverpod. Rather, you should start using hooks because you want to use hooks.

Using hooks is a tradeoff. They can be great for producing robust and reusable code, but they are also a new concept to learn, and they can be confusing at first.
Hooks aren't a core Flutter concept. As such, they will feel out of place in Flutter/Dart.

## What are hooks?

Hooks are functions used inside widgets. They are designed as an alternative to [StatefulWidget](https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html)s, to make logic more reusable and composable.

Hooks are a concept coming from [React](https://reactjs.org/), and [flutter_hooks](https://github.com/rrousselGit/flutter_hooks) is merely a port of the React implementation to Flutter.
As such, yes, hooks may feel a bit out of place in Flutter. Ideally, in the future we would have a solution to the problem that hooks solves, designed specifically for Flutter.

If Riverpod's providers are for "global" application state, hooks are for local widget state. Hooks are typically used for dealing with stateful UI objects, such as [TextEditingController](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html), [AnimationController](https://api.flutter.dev/flutter/animation/AnimationController-class.html).
They can also serve as a replacement to the "builder" pattern, replacing widgets such as [FutureBuilder](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)/[TweenAnimatedBuilder](https://api.flutter.dev/flutter/widgets/TweenAnimationBuilder-class.html) by an alternative that does not involve "nesting" – drastically improving readability.

In general, hooks are helpful for:

*   Forms
*   Animations
*   Reacting to user events
*   etc.

As an example, we could use hooks to manually implement a fade-in animation, where a widget starts invisible and slowly appears.

If we were to use [StatefulWidget](https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html), the code would look like this:

```dart
class FadeIn extends StatefulWidget {
  const FadeIn({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  _FadeInState createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
```

With hooks, this can be rewritten as:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FadeIn extends HookWidget {
  const FadeIn({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: const Duration(seconds: 1));
    final animation = useMemoized(() => Tween(begin: 0.0, end: 1.0).animate(controller), [controller]);

    useEffect(() {
      controller.forward();
      return controller.dispose;
    }, [controller]);

    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
```

This provides a few benefits:

*   The code is shorter and easier to read.
*   The logic is reusable. We could create a custom hook `useFadeIn` that encapsulates the logic:

    ```dart
    Animation<double> useFadeIn() {
      final controller = useAnimationController(duration: const Duration(seconds: 1));
      final animation = useMemoized(() => Tween(begin: 0.0, end: 1.0).animate(controller), [controller]);

      useEffect(() {
        controller.forward();
        return controller.dispose;
      }, [controller]);

      return animation;
    }

    class FadeIn extends HookWidget {
      const FadeIn({Key? key, required this.child}) : super(key: key);
      final Widget child;

      @override
      Widget build(BuildContext context) {
        final animation = useFadeIn();
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      }
    }
    ```

    This custom hook can then be used in any widget that extends `HookWidget`.

*   The life-cycle is handled automatically. The controller is created when the widget is first built, it is updated if the widget rebuilds, and the controller is correctly released when the widget is unmounted.

*   It is possible to use hooks as many time as we want within the same widget.
    As such, we can create multiple `AnimationController` if we want:

    ```dart
    @override
    Widget build(BuildContext context) {
      final animationController = useAnimationController(
        duration: const Duration(seconds: 1),
      );
      final animationController2 = useAnimationController(
        duration: const Duration(seconds: 2),
      );

      return Container();
    }
    ```

    This is something that is not possible with `StatefulWidget`, as `StatefulWidget` only has one `vsync` ticker.

*   Hooks are composable. It is possible to combine multiple hooks together to create new hooks.

*   Hooks are testable. It is possible to test hooks in isolation, without having to create a full widget tree.

*   Hooks are reusable. The `useFadeIn` custom hook is reusable. If we wanted, we could use that `useFadeIn` function in a completely different widget, and it would still work!

## The rules of hooks

Hooks comes with unique constraints:

*   They can only be used within the `build` method of a widget that extends [HookWidget](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/HookWidget-class.html):

    **Good**:

    ```dart
    class Example extends HookWidget {
      @override
      Widget build(BuildContext context) {
        useAnimationController();
        return Container();
      }
    }
    ```

    **Bad**:

    ```dart
    class Example extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        // ❌ Error: Hooks can only be called inside the build method of a HookWidget
        useAnimationController();
        return Container();
      }
    }

    class Example extends HookWidget {
      // ❌ Error: Hooks can only be called inside the build method of a HookWidget
      final controller = useAnimationController();

      @override
      Widget build(BuildContext context) {
        return Container();
      }
    }

    class Example extends HookWidget {
      @override
      Widget build(BuildContext context) {
        if (true) {
          // ❌ Error: Hooks must be called unconditionally
          useAnimationController();
        }
        return Container();
      }
    }
    ```

*   Hooks must be called unconditionally. This means that hooks cannot be called inside `if` statements, loops, or other conditional logic.

These rules are in place to ensure that hooks are called in the same order every time a widget builds. This is crucial for hooks to work correctly.

## Hooks and Riverpod

Although both [flutter_hooks](https://github.com/rrousselGit/flutter_hooks) and Riverpod are separate packages, they are often used together.

This is why there is a package called [hooks_riverpod](https://pub.dev/packages/hooks_riverpod), which combines both packages.

> Note that `hooks_riverpod` does not export `flutter_hooks`. If you want to use hooks, you still need to add `flutter_hooks` to your dependencies separately. If you want to use them, installing [hooks_riverpod](https://pub.dev/packages/hooks_riverpod) is not enough. You will still need to add [flutter_hooks](https://github.com/rrousselGit/flutter_hooks) to your dependencies.
> See [Getting started](/docs/introduction/getting_started#installing-the-package) for more information.

### Usage

In some cases, you may want to write a Widget that uses both hooks and Riverpod.
But as you may have already noticed, both hooks and Riverpod provide their own custom widget base type: [HookWidget](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/HookWidget-class.html) and [ConsumerWidget](https://pub.dev/documentation/flutter_riverpod/latest/flutter_riverpod/ConsumerWidget-class.html).
But classes can only extend one superclass at a time.

To solve this problem, you can use the [hooks_riverpod](https://pub.dev/packages/hooks_riverpod) package.
This package provides a [HookConsumerWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/HookConsumerWidget-class.html) class that combines both [HookWidget](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/HookWidget-class.html) and [ConsumerWidget](https://pub.dev/documentation/flutter_riverpod/latest/flutter_riverpod/ConsumerWidget-class.html) into a single type.

You can therefore subclass [HookConsumerWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/HookConsumerWidget-class.html) instead of [HookWidget](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/HookWidget-class.html):

```dart
// We extend HookConsumerWidget instead of HookWidget
class Example extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(duration: const Duration(seconds: 1));
    return Container();
  }
}
```

Alternatively, if you prefer composition over inheritance, it is entirely possible to use both `HookBuilder` and `Consumer` in combination, with a plain `StatelessWidget`:

```dart
class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final controller = useAnimationController(duration: const Duration(seconds: 1));
        return Consumer(
          builder: (context, ref, child) {
            final value = ref.watch(myProvider);
            return Text('$value');
          },
        );
      },
    );
  }
}
```

If you like this approach, [hooks_riverpod](https://pub.dev/packages/hooks_riverpod) streamlines it by providing [HookConsumer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/HookConsumer-class.html), which is the combination of both builders in one:

```dart
class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HookConsumer(
      builder: (context, ref, child) {
        final controller = useAnimationController(duration: const Duration(seconds: 1));
        final value = ref.watch(myProvider);
        return Text('$value');
      },
    );
  }
}
```