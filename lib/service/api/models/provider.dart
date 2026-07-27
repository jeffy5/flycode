import 'package:json_annotation/json_annotation.dart';

part 'provider.g.dart';

@JsonSerializable()
class ProviderModel {
  final String id;
  final String name;
  final String source;
  final List<String> env;
  final String? key;
  final Map<String, dynamic> options;
  final Map<String, ModelInfo> models;

  ProviderModel({
    required this.id,
    required this.name,
    required this.source,
    required this.env,
    this.key,
    required this.options,
    required this.models,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProviderModelToJson(this);
}

@JsonSerializable()
class ModelInfo {
  final String id;
  final String providerID;
  final ModelApi api;
  final String name;
  final String? family;
  final ModelCapabilities capabilities;
  final ModelCost cost;
  final ModelLimit limit;
  final String status;
  final Map<String, dynamic> options;
  final Map<String, String> headers;
  @JsonKey(name: 'release_date')
  final String releaseDate;
  final Map<String, Map<String, dynamic>>? variants;

  ModelInfo({
    required this.id,
    required this.providerID,
    required this.api,
    required this.name,
    this.family,
    required this.capabilities,
    required this.cost,
    required this.limit,
    required this.status,
    required this.options,
    required this.headers,
    required this.releaseDate,
    this.variants,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ModelInfoToJson(this);
}

@JsonSerializable()
class ModelApi {
  final String id;
  final String? url;
  final String? npm;

  ModelApi({required this.id, this.url, this.npm});

  factory ModelApi.fromJson(Map<String, dynamic> json) =>
      _$ModelApiFromJson(json);
  Map<String, dynamic> toJson() => _$ModelApiToJson(this);
}

@JsonSerializable()
class ModelCapabilities {
  final bool? temperature;
  final bool? reasoning;
  final bool? attachment;
  final bool? toolcall;
  final ModelCapabilityIO? input;
  final ModelCapabilityIO? output;
  final dynamic interleaved;

  ModelCapabilities({
    this.temperature,
    this.reasoning,
    this.attachment,
    this.toolcall,
    this.input,
    this.output,
    this.interleaved,
  });

  factory ModelCapabilities.fromJson(Map<String, dynamic> json) =>
      _$ModelCapabilitiesFromJson(json);
  Map<String, dynamic> toJson() => _$ModelCapabilitiesToJson(this);
}

@JsonSerializable()
class ModelCapabilityIO {
  @JsonKey(name: 'text')
  final bool? text;
  @JsonKey(name: 'audio')
  final bool? audio;
  @JsonKey(name: 'image')
  final bool? image;
  @JsonKey(name: 'video')
  final bool? video;
  @JsonKey(name: 'pdf')
  final bool? pdf;

  ModelCapabilityIO({this.text, this.audio, this.image, this.video, this.pdf});

  factory ModelCapabilityIO.fromJson(Map<String, dynamic> json) =>
      _$ModelCapabilityIOFromJson(json);
  Map<String, dynamic> toJson() => _$ModelCapabilityIOToJson(this);
}

@JsonSerializable()
class ModelCost {
  final double input;
  final double output;
  final CacheCost cache;
  @JsonKey(name: 'experimentalOver200K')
  final ExperimentalCost? experimentalOver200k;

  ModelCost({
    required this.input,
    required this.output,
    required this.cache,
    this.experimentalOver200k,
  });

  factory ModelCost.fromJson(Map<String, dynamic> json) =>
      _$ModelCostFromJson(json);
  Map<String, dynamic> toJson() => _$ModelCostToJson(this);
}

@JsonSerializable()
class CacheCost {
  @JsonKey(name: 'read')
  final double? read;
  @JsonKey(name: 'write')
  final double? write;

  CacheCost({this.read, this.write});

  factory CacheCost.fromJson(Map<String, dynamic> json) =>
      _$CacheCostFromJson(json);
  Map<String, dynamic> toJson() => _$CacheCostToJson(this);
}

@JsonSerializable()
class ExperimentalCost {
  final double input;
  final double output;
  final CacheCost cache;

  ExperimentalCost({
    required this.input,
    required this.output,
    required this.cache,
  });

  factory ExperimentalCost.fromJson(Map<String, dynamic> json) =>
      _$ExperimentalCostFromJson(json);
  Map<String, dynamic> toJson() => _$ExperimentalCostToJson(this);
}

@JsonSerializable()
class ModelLimit {
  final int context;
  final int? input;
  final int output;

  ModelLimit({required this.context, this.input, required this.output});

  factory ModelLimit.fromJson(Map<String, dynamic> json) =>
      _$ModelLimitFromJson(json);
  Map<String, dynamic> toJson() => _$ModelLimitToJson(this);
}

@JsonSerializable()
class ProviderListResponse {
  final List<ProviderModel> all;
  @JsonKey(name: 'default')
  final Map<String, String> defaultProvider;
  final List<String> connected;

  ProviderListResponse({
    required this.all,
    required this.defaultProvider,
    required this.connected,
  });

  factory ProviderListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProviderListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProviderListResponseToJson(this);
}
