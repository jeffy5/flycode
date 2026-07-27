# Consumers | Riverpod

A "Consumer" is a type of widget that bridges the gap between the Widget tree and the Provider tree.

The only real difference between a Consumer and typical widgets is that Consumers get access to a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html). This enables them to read providers and listen to their changes. See [Refs](/docs/concepts2/refs) for more information.

Consumers come in a few different flavors, mostly for personal preference. You will find:

*   [Consumer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Consumer-class.html), a "builder" widget (similar to [FutureBuilder](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)).
    It allows widgets to interact with providers without having to subclass something other than `StatelessWidget` or `StatefulWidget`.
    ```dart
    // We subclass StatelessWidget as usual
    class MyWidget extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        // A FutureBuilder-like widget
        return Consumer(
          // The "builder" callback gives us a "ref" parameter
          builder: (context, ref, _) {
            // We can use that "ref" to listen to providers
            final value = ref.watch(myProvider);
            return Text(value.toString());
          },
        );
      }
    }
    ```

*   [ConsumerWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerWidget-class.html), a variant of `StatelessWidget` widget.
    Instead of subclassing `StatelessWidget`, you subclass `ConsumerWidget`. It will behave the same, besides the fact that `build` receives an extra [WidgetRef](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/WidgetRef-class.html) parameter.
    ```dart
    // We subclass ConsumerWidget instead of StatelessWidget
    class MyWidget extends ConsumerWidget {
      // "build" receives an extra parameter
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        // We can use that "ref" to listen to providers
        final value = ref.watch(myProvider);
        return Text(value.toString());
      }
    }
    ```

*   [ConsumerStatefulWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerStatefulWidget-class.html), a variant of `StatefulWidget` widget.
    Again, instead of subclassing `StatefulWidget`, you subclass `ConsumerStatefulWidget`.
    And instead of `State`, you subclass [ConsumerState](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerState-class.html).
    The unique part is that [ConsumerState](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerState-class.html) has a `ref` property.
    ```dart
    // We subclass ConsumerStatefulWidget instead of StatefulWidget
    class MyWidget extends ConsumerStatefulWidget {
      @override
      ConsumerState<MyWidget> createState() => _MyWidgetState();
    }

    // We subclass ConsumerState instead of State
    class _MyWidgetState extends ConsumerState<MyWidget> {
      // A "this.ref" property is available
      @override
      Widget build(BuildContext context) {
        // We can use that "ref" to listen to providers
        final value = ref.watch(myProvider);
        return Text(value.toString());
      }
    }
    ```

Alternatively, you will find extra consumers in the [hooks_riverpod](https://pub.dev/packages/hooks_riverpod) package.
Those combine Riverpod consumers with [flutter_hooks](https://pub.dev/packages/flutter_hooks).
If you don't care about hooks, you can ignore them.

### Which one to use?

The choice of which consumer to use is mostly a matter of personal preference.
You could use [Consumer](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Consumer-class.html) for everything. It is a slightly more verbose option than the others.
But this is a reasonable price to pay if you do not like how Riverpod hijacks `StatelessWidget` and `StatefulWidget`.

But if you do not have a strong opinion, we recommend using [ConsumerWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerWidget-class.html) (or [ConsumerStatefulWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerStatefulWidget-class.html) when you need a `State`).

### Why can't we use `StatelessWidget` + `context.watch`?

In alternative packages like [provider](https://pub.dev/packages/provider), you can use `context.watch` to listen to providers.
This works inside any widget, as long as you have a `BuildContext`. So why isn't this the case in Riverpod?

The reason is that relying purely on `BuildContext` instead of a [Ref](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/Ref-class.html) would prevent the implementation
of Riverpod's [Automatic disposal](/docs/concepts2/auto_dispose) in a reliable way. There *are* tricks to make an implementation that "mostly works" with `BuildContext`.
The problem is that there are lots of subtle edge-cases which could silently break the auto-dispose feature.

This would cause memory leaks, but that's not the real issue.
Automatic disposal is more importantly about stopping the execution of code that is no longer needed.
If auto-dispose fails to dispose a provider, then that provider may continuously perform network requests in the background.

Riverpod preferred to not compromise on reliability for the sake of a little convenience.

> To alleviate the downsides of having to use [ConsumerWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerWidget-class.html)/[ConsumerStatefulWidget](https://pub.dev/documentation/hooks_riverpod/latest/hooks_riverpod/ConsumerStatefulWidget-class.html) instead of `StatelessWidget`/`StatefulWidget`,
> Riverpod offers various refactors in IDEs like VSCode and Android Studio.
>
> ![Refactor to Consumer](/assets/images/convert_to_class_provider-6752ac8cea1f992caa9227f07f2623e8.gif)
>
> To enable them in your IDE, see [Getting started](/docs/introduction/getting_started#enabling-riverpod_lintcustom_lint)