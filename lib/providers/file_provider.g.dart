// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileContent)
final fileContentProvider = FileContentFamily._();

final class FileContentProvider
    extends
        $FunctionalProvider<
          AsyncValue<FileContent>,
          FileContent,
          FutureOr<FileContent>
        >
    with $FutureModifier<FileContent>, $FutureProvider<FileContent> {
  FileContentProvider._({
    required FileContentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fileContentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fileContentHash();

  @override
  String toString() {
    return r'fileContentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FileContent> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FileContent> create(Ref ref) {
    final argument = this.argument as String;
    return fileContent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FileContentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fileContentHash() => r'7acef739bb107569a0deef4acb9c62bc13597512';

final class FileContentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FileContent>, String> {
  FileContentFamily._()
    : super(
        retry: null,
        name: r'fileContentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FileContentProvider call(String path) =>
      FileContentProvider._(argument: path, from: this);

  @override
  String toString() => r'fileContentProvider';
}
