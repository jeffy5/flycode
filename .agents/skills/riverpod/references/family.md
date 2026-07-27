# Family | Riverpod

One of Riverpod's most powerful feature is called "Families".
In short, it allows a provider to be associated with multiple independent states, based on a unique parameter combination.

A typical use-case is to fetch data from a remote API, where the response depends on some parameters (such as a user ID or a search query or a page number).
It enables defining a single provider that can be used to fetch and cache any possible parameter combination.

![Graph showing how family links a provider to multiple independent states](/assets/images/users-bd49f38785e493d3d0d2576683a006c1.svg)

> If normal providers can be assimilated to a variable, then "family" providers can be assimilated to a Map.

## Creating a Family

Defining a family is done by slightly modifying the provider definition to receive a parameter.

For functional providers, the syntax is as follows:

**riverpod**
```dart
// When not using code-generation, providers can use ".family".
// This adds one generic parameter corresponding to the type of the parameter.
// The initialization function then receives the parameter.
final userProvider = FutureProvider.autoDispose.family<User, String>((
  ref,
  userId,
) async {
  final json = await http.get('api/user/$userId');
  return User.fromJson(json);
});
```

**riverpod_generator**
```dart
@riverpod
Future<User> user(Ref ref, String userId) async {
  final json = await http.get('api/user/$userId');
  return User.fromJson(json);
}
```

For notifier providers, the syntax is as follows:

**riverpod**
```dart
// When not using code-generation, providers can use ".family".
// This adds one generic parameter corresponding to the type of the parameter.
// The initialization function then receives the parameter.
final userNotifierProvider = NotifierProvider.autoDispose.family<UserNotifier, User, String>((
  ref,
  userId,
) => UserNotifier(userId: userId));

class UserNotifier extends Notifier<User> {
  UserNotifier({required this.userId});
  final String userId;

  @override
  User build() {
    // We can use the "userId" here too
    print(userId);
    ...
  }
}
```

**riverpod_generator**
```dart
@riverpod
class UserNotifier extends _$UserNotifier {
  // Using the parameter in the build method. This ensures that the parameter
  // is available immediately, and that it is not null.
  @override
  User build(String userId) {
    print(userId);
    ...
  }
}
```

> It is recommended to enable automatic disposal when using families.
> This avoids memory leaks in case the parameter changes and the previous state is no longer needed.

## Using a Family

Providers that receive parameters see their usage slightly modified too.

Long story short, you need to pass the parameters that your provider expects, as follows:

```dart
final user = ref.watch(userProvider('123'));
```

> The parameter of a family is passed positionally.
> This means that `userProvider(param)` is equivalent to `userProvider.call(param)`.

> The parameter is used to create a new key for the provider. As such, if the `==`/`hashCode` of a parameter changes, the value obtained will be different.
>
> Therefore code such as the following is incorrect:
>
> ```dart
> // Incorrect parameter, as `[1, 2, 3] != [1, 2, 3]`
> ref.watch(myProvider([1, 2, 3]));
> ```
>
> Instead, ensure that the parameter has a consistent `==`/`hashCode`. For complex objects, use packages like `freezed` or `equatable`.
>
> Riverpod has a lint rule to catch this common mistake. To enable it, install `riverpod_lint` and enable the [provider_parameters](https://github.com/rrousselGit/riverpod/tree/master/packages/riverpod_lint#provider_parameters) lint rule. Then, the previous snippet would show a warning.
> See [Getting started](/docs/introduction/getting_started#enabling-riverpod_lintcustom_lint) for installation steps.

You can read as many "family" providers as you want, and they will all be independent. As such, it is legal to do:

```dart
class Example extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Both users will have their own independent state.
    // Updating one will not update the other.
    final user1 = ref.watch(userProvider('123'));
    final user2 = ref.watch(userProvider('456'));
    return Text('$user1 $user2');
  }
}
```