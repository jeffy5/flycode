# DO/DON'T | Riverpod

To ensure good maintainability of your code, here is a list of good practices you should follow when using Riverpod.

This list is not exhaustive, and is subject to change. If you have any suggestions, feel free to [open an issue](https://github.com/rrousselGit/riverpod/issues/new?assignees=rrousselGit&labels=documentation%2C+needs+triage&projects=&template=example_request.md&title=).

Items in this list are not in any particular order.

A good portion of these recommendations can be enforced with [riverpod_lint](https://pub.dev/packages/riverpod_lint).
See [Getting started](/docs/introduction/getting_started#enabling-riverpod_lintcustom_lint) for installation instructions.

## AVOID initializing providers in a widget

Providers should initialize themselves. They should not be initialized by an external element such as a widget.

Failing to do so could cause possible race conditions and unexpected behaviors.

**DON'T**
```dart
class WidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Bad: the provider should initialize itself
    ref.read(provider).init();
  }
}
```

**CONSIDER**

There is no "one-size fits all" solution to this problem.
If your initialization logic depends on factors external to the provider, often the correct place to put such logic is in the `onPressed` method of a button triggering navigation:

```dart
ElevatedButton(
  onPressed: () {
    ref.read(provider).init();
    Navigator.of(context).push(...);
  },
  child: Text('Navigate'),
)
```

## AVOID using providers for Ephemeral state.

Providers are designed to be for shared business state.
They are not meant to be used for [Ephemeral state](https://docs.flutter.dev/data-and-backend/state-mgmt/ephemeral-vs-app#ephemeral-state), such as for:

*   The currently selected item.
*   Form state
    Because leaving and re-entering the form should typically reset the form state.
    This includes pressing the back button during a multi-page forms.
*   Animations.
*   Generally everything that Flutter deals with a "controller" (e.g. `TextEditingController`)

If you are looking for a way to handle local widget state, consider using [flutter_hooks](https://pub.dev/packages/flutter_hooks) instead.

One reason why this is discouraged is that such state is often scoped to a route.
Failing to do so could break your app's back button, due to a new page overriding the state of a previous page.

For instance say we were to store the currently selected `book` in a provider:

```dart
final selectedBookProvider = StateProvider<String?>((ref) => null);
```

One challenge we could face is, the navigation history could look like:

```
/books
/books/42
/books/21
```

In this scenario, when pressing the back button, we should expect to go back to `/books/42`.
But if we were to use `selectedBookProvider` to store the selected book, the selected ID would not reset to its previous value, and we would keep seeing `/books/21`.

## DON'T perform side effects during the initialization of a provider

Providers should generally be used to represent a "read" operation.
You should not use them for "write" operations, such as submitting a form.

Using providers for such operations could have unexpected behaviors, such as skipping a side-effect if a previous one was performed.

If you are looking at a way to handle loading/error states of a side-effect, see [Mutations (experimental)](/docs/concepts2/mutations).

**DON'T**:

```dart
final submitProvider = FutureProvider((ref) async {
  final formState = ref.watch(formState);

  // Bad: Providers should not be used for "write" operations.
  return http.post('https://my-api.com', body: formState.toJson());
});
```

## PREFER ref.watch/read/listen (and similar APIs) with statically known providers

Riverpod strongly recommends enabling lint rules (via `riverpod_lint`).
But for lints to be effective, your code should be written in a way that is statically analysable.

Failing to do so could make it harder to spot bugs or cause false positives with lints.

**Do**:

```dart
final provider = Provider((ref) => 42);

...

// OK because `provider` is a final variable, so its value is known at compile time.
// The linter can verify that this is a valid usage.
ref.watch(provider);
```

**Don't**:

```dart
// `myProvider` is not a final variable, so its value is not known at compile time.
// The linter cannot verify that this is a valid usage.
final myProvider = getProvider();

...

ref.watch(myProvider);
```

This also applies to dynamic access such as via a switch or if/else.

```dart
// `myProvider` is not a final variable, so its value is not known at compile time.
// The linter cannot verify that this is a valid usage.
ProviderBase getProvider() => throw UnimplementedError();

...

ref.watch(getProvider());
```

**What about `provider.select`?**

`provider.select` is not statically analyzable. For this reason, it is not recommended to use it.

Instead, you should prefer creating a new provider that exposes the selected value. This will allow the linter to verify the usage and provide better error messages.

```dart
final userProvider = FutureProvider((ref) async => User(name: 'John', age: 42));

// GOOD
final userNameProvider = Provider((ref) {
  return ref.watch(userProvider).maybeWhen(
        data: (user) => user.name,
        orElse: () => null,
      );
});
```

This pattern has the additional benefit of being more performant. By creating a dedicated provider for the selected value, you are ensuring that only widgets listening to `userNameProvider` rebuild when the user's name changes, rather than all widgets listening to `userProvider`.

For more information on reducing provider/widget rebuilds, see [How to reduce provider/widget rebuilds](/docs/how_to/select).
