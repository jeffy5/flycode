// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.

@ProviderFor(PendingQuestionsNotifier)
final pendingQuestionsProvider = PendingQuestionsNotifierProvider._();

/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.
final class PendingQuestionsNotifierProvider
    extends
        $AsyncNotifierProvider<
          PendingQuestionsNotifier,
          List<QuestionRequest>
        > {
  /// Holds the list of pending QuestionRequests for the current project directory.
  /// SSE events add/remove entries; initial load comes from GET /question.
  PendingQuestionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingQuestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingQuestionsNotifierHash();

  @$internal
  @override
  PendingQuestionsNotifier create() => PendingQuestionsNotifier();
}

String _$pendingQuestionsNotifierHash() =>
    r'a11195ca5ed99c2668709d5d32fb134733144753';

/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.

abstract class _$PendingQuestionsNotifier
    extends $AsyncNotifier<List<QuestionRequest>> {
  FutureOr<List<QuestionRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<QuestionRequest>>, List<QuestionRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<QuestionRequest>>,
                List<QuestionRequest>
              >,
              AsyncValue<List<QuestionRequest>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(currentSessionHasQuestion)
final currentSessionHasQuestionProvider = CurrentSessionHasQuestionFamily._();

final class CurrentSessionHasQuestionProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  CurrentSessionHasQuestionProvider._({
    required CurrentSessionHasQuestionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentSessionHasQuestionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentSessionHasQuestionHash();

  @override
  String toString() {
    return r'currentSessionHasQuestionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return currentSessionHasQuestion(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentSessionHasQuestionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentSessionHasQuestionHash() =>
    r'6faed8d6d0745bdd087c44009a79db677efb2155';

final class CurrentSessionHasQuestionFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  CurrentSessionHasQuestionFamily._()
    : super(
        retry: null,
        name: r'currentSessionHasQuestionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentSessionHasQuestionProvider call(String sessionId) =>
      CurrentSessionHasQuestionProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'currentSessionHasQuestionProvider';
}
