// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(questionApi)
final questionApiProvider = QuestionApiProvider._();

final class QuestionApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuestionApi>,
          QuestionApi,
          FutureOr<QuestionApi>
        >
    with $FutureModifier<QuestionApi>, $FutureProvider<QuestionApi> {
  QuestionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questionApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questionApiHash();

  @$internal
  @override
  $FutureProviderElement<QuestionApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuestionApi> create(Ref ref) {
    return questionApi(ref);
  }
}

String _$questionApiHash() => r'c065fe8d4773b714fbccebb4a5610de2f1a64c61';
