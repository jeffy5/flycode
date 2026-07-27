// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(commandApi)
final commandApiProvider = CommandApiProvider._();

final class CommandApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<CommandApi>,
          CommandApi,
          FutureOr<CommandApi>
        >
    with $FutureModifier<CommandApi>, $FutureProvider<CommandApi> {
  CommandApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandApiHash();

  @$internal
  @override
  $FutureProviderElement<CommandApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CommandApi> create(Ref ref) {
    return commandApi(ref);
  }
}

String _$commandApiHash() => r'b631eb06d4cc93e23b3603558c5bd7a8508b65b2';

@ProviderFor(commands)
final commandsProvider = CommandsProvider._();

final class CommandsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Command>>,
          List<Command>,
          FutureOr<List<Command>>
        >
    with $FutureModifier<List<Command>>, $FutureProvider<List<Command>> {
  CommandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandsHash();

  @$internal
  @override
  $FutureProviderElement<List<Command>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Command>> create(Ref ref) {
    return commands(ref);
  }
}

String _$commandsHash() => r'05d1b153e3721c83b7d0b7415b9ff6a8dfa15a6e';
