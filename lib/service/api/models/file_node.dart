class FileNode {
  final String name;
  final String path;
  final String absolute;
  final String type;
  final bool ignored;

  FileNode({
    required this.name,
    required this.path,
    required this.absolute,
    required this.type,
    required this.ignored,
  });

  bool get isDirectory => type == 'directory';

  factory FileNode.fromJson(Map<String, dynamic> json) => FileNode(
    name: json['name'] as String,
    path: json['path'] as String,
    absolute: json['absolute'] as String,
    type: json['type'] as String,
    ignored: json['ignored'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'absolute': absolute,
    'type': type,
    'ignored': ignored,
  };
}
