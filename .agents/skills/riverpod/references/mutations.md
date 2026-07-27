# Mutations (experimental) | Riverpod

> Mutations are experimental, and the API may change in a breaking way without a major version bump.

Mutations, in Riverpod, are objects which enable the user interface to react to state changes.
A common use-case is displaying a loading indicator while a form is being submitted

In short, mutations are to achieve effects such as this:
![Submit progress indicator](/assets/images/spinner-6014ac9b22357d59449e6842088656f3.gif)!

Without mutations, you would have to store the progress of the form submission directly inside the state of a provider. This is not ideal as it pollutes the state of your provider with UI concerns ; and it involves a lot of boilerplate code to handle the loading state, error state, and success state.

Mutations are designed to handle these concerns in a more elegant way.

## Defining a mutation

Mutations are instances of the [Mutation](https://pub.dev/documentation/riverpod/latest/experimental_mutation/Mutation-class.html) object, stored in a final variable somewhere.

```dart
// A mutation to track the "add todo" operation.
// The generic type is optional and can be specified to enable the UI to interact
// with the result of the mutation.
final addTodo = Mutation<Todo>();
```

> Typically, this variable will either be global or as a `static final` variable on a [Notifier](https://pub.dev/documentation/riverpod/latest/riverpod/Notifier-class.html).

## Listening to a mutation

Once we've defined a mutation, we can start using it inside [Consumers](/docs/concepts2/consumers) or [Providers](/docs/concepts2/providers).
For this, we will need a [Refs](/docs/concepts2/refs) and pick a listening method of our choice (typically [Ref.watch](https://pub.dev/documentation/riverpod/latest/riverpod/Ref/watch.html)).

A typical example would be:

```dart
class Example extends ConsumerWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We listen to the current state of the "addTodo" mutation.
    // Listening to this will not perform any side effects by itself.
    final addTodoState = ref.watch(addTodo);

    return Row(
      children: [
        ElevatedButton(
          style: ButtonStyle(
            // If there is an error, we show the button in red
            backgroundColor: switch (addTodoState) {
              MutationError() => const WidgetStatePropertyAll(Colors.red),
              _ => null,
            },
          ),
          onPressed: () {
            addTodo.run(ref, (tsx) async {
              // todo
            });
          },
          child: const Text('Add todo'),
        ),

        // The operation is pending, let's show a progress indicator
        if (addTodoState is MutationPending) ...[
          const SizedBox(width: 8),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }
}
```

### Scoping a mutation

Sometimes, you may want to have multiple instances of the same mutation.

This can include things like an id, or any other parameter that makes the mutation unique.

This is useful if you want to have multiple instances of the same mutation, such as deleting a specific item in a list

Simply call the mutation with the unique key:

```dart
final removeTodo = Mutation<void>();
final removeTodoWithId = removeTodo(todo.id);
```

### Generics

Mutations are typically used without generics, such as `final addTodo = Mutation<void>();`. The generic type is optional, and can be used when the UI needs to interact with the result of the mutation.

This can be useful if an api response may have different response types based on the input parameters, such as with deserialization.

```dart
final create = Mutation<ApiResponse>();
final createTodo = create<CreatedResponse<Todo>>('my-todo-mutation');
```

### Running a mutation

Once we have defined and listened to our mutation, we can run it. Mutations are run by calling the `run` method:

```dart
return ElevatedButton(
  onPressed: () {
    // Trigger the mutation, and run the callback.
    // During the callback, we obtain a MutationTransaction (tsx) object
    // which we can use to access providers and perform operations.
    addTodo.run(ref, (tsx) async {
      // ...
    });
  },
  child: const Text('Add todo'),
);
```

### Resetting a mutation

You can reset a mutation to its idle state by calling the [Mutation.reset](https://pub.dev/documentation/riverpod/latest/experimental_mutation/Mutation/reset.html) method:

```dart
return ElevatedButton(
  onPressed: () {
    // Reset the mutation to its idle state.
    addTodo.reset(ref);
  },
  child: const Text('Reset'),
);
```