import 'package:json_annotation/json_annotation.dart';

part 'health.g.dart';

@JsonSerializable()
class Health {
  final bool healthy;
  final String version;

  Health({required this.healthy, required this.version});

  factory Health.fromJson(Map<String, dynamic> json) => _$HealthFromJson(json);
  Map<String, dynamic> toJson() => _$HealthToJson(this);
}
