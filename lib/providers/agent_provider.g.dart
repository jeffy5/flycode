// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the list of available agents from the server, filtered to only
/// include agents that are visible in the switcher (mode != 'subagent' and
/// not hidden).

@ProviderFor(agents)
final agentsProvider = AgentsProvider._();

/// Fetches the list of available agents from the server, filtered to only
/// include agents that are visible in the switcher (mode != 'subagent' and
/// not hidden).

final class AgentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Agent>>,
          List<Agent>,
          FutureOr<List<Agent>>
        >
    with $FutureModifier<List<Agent>>, $FutureProvider<List<Agent>> {
  /// Fetches the list of available agents from the server, filtered to only
  /// include agents that are visible in the switcher (mode != 'subagent' and
  /// not hidden).
  AgentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentsHash();

  @$internal
  @override
  $FutureProviderElement<List<Agent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Agent>> create(Ref ref) {
    return agents(ref);
  }
}

String _$agentsHash() => r'7459b2341770776beb7fdd743ab5a5805e6bd049';
