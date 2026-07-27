// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderModel _$ProviderModelFromJson(Map<String, dynamic> json) =>
    ProviderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      source: json['source'] as String,
      env: (json['env'] as List<dynamic>).map((e) => e as String).toList(),
      key: json['key'] as String?,
      options: json['options'] as Map<String, dynamic>,
      models: (json['models'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, ModelInfo.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ProviderModelToJson(ProviderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'source': instance.source,
      'env': instance.env,
      'key': instance.key,
      'options': instance.options,
      'models': instance.models,
    };

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => ModelInfo(
  id: json['id'] as String,
  providerID: json['providerID'] as String,
  api: ModelApi.fromJson(json['api'] as Map<String, dynamic>),
  name: json['name'] as String,
  family: json['family'] as String?,
  capabilities: ModelCapabilities.fromJson(
    json['capabilities'] as Map<String, dynamic>,
  ),
  cost: ModelCost.fromJson(json['cost'] as Map<String, dynamic>),
  limit: ModelLimit.fromJson(json['limit'] as Map<String, dynamic>),
  status: json['status'] as String,
  options: json['options'] as Map<String, dynamic>,
  headers: Map<String, String>.from(json['headers'] as Map),
  releaseDate: json['release_date'] as String,
  variants: (json['variants'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
  'id': instance.id,
  'providerID': instance.providerID,
  'api': instance.api,
  'name': instance.name,
  'family': instance.family,
  'capabilities': instance.capabilities,
  'cost': instance.cost,
  'limit': instance.limit,
  'status': instance.status,
  'options': instance.options,
  'headers': instance.headers,
  'release_date': instance.releaseDate,
  'variants': instance.variants,
};

ModelApi _$ModelApiFromJson(Map<String, dynamic> json) => ModelApi(
  id: json['id'] as String,
  url: json['url'] as String?,
  npm: json['npm'] as String?,
);

Map<String, dynamic> _$ModelApiToJson(ModelApi instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'npm': instance.npm,
};

ModelCapabilities _$ModelCapabilitiesFromJson(Map<String, dynamic> json) =>
    ModelCapabilities(
      temperature: json['temperature'] as bool?,
      reasoning: json['reasoning'] as bool?,
      attachment: json['attachment'] as bool?,
      toolcall: json['toolcall'] as bool?,
      input: json['input'] == null
          ? null
          : ModelCapabilityIO.fromJson(json['input'] as Map<String, dynamic>),
      output: json['output'] == null
          ? null
          : ModelCapabilityIO.fromJson(json['output'] as Map<String, dynamic>),
      interleaved: json['interleaved'],
    );

Map<String, dynamic> _$ModelCapabilitiesToJson(ModelCapabilities instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'reasoning': instance.reasoning,
      'attachment': instance.attachment,
      'toolcall': instance.toolcall,
      'input': instance.input,
      'output': instance.output,
      'interleaved': instance.interleaved,
    };

ModelCapabilityIO _$ModelCapabilityIOFromJson(Map<String, dynamic> json) =>
    ModelCapabilityIO(
      text: json['text'] as bool?,
      audio: json['audio'] as bool?,
      image: json['image'] as bool?,
      video: json['video'] as bool?,
      pdf: json['pdf'] as bool?,
    );

Map<String, dynamic> _$ModelCapabilityIOToJson(ModelCapabilityIO instance) =>
    <String, dynamic>{
      'text': instance.text,
      'audio': instance.audio,
      'image': instance.image,
      'video': instance.video,
      'pdf': instance.pdf,
    };

ModelCost _$ModelCostFromJson(Map<String, dynamic> json) => ModelCost(
  input: (json['input'] as num).toDouble(),
  output: (json['output'] as num).toDouble(),
  cache: CacheCost.fromJson(json['cache'] as Map<String, dynamic>),
  experimentalOver200k: json['experimentalOver200K'] == null
      ? null
      : ExperimentalCost.fromJson(
          json['experimentalOver200K'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ModelCostToJson(ModelCost instance) => <String, dynamic>{
  'input': instance.input,
  'output': instance.output,
  'cache': instance.cache,
  'experimentalOver200K': instance.experimentalOver200k,
};

CacheCost _$CacheCostFromJson(Map<String, dynamic> json) => CacheCost(
  read: (json['read'] as num?)?.toDouble(),
  write: (json['write'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CacheCostToJson(CacheCost instance) => <String, dynamic>{
  'read': instance.read,
  'write': instance.write,
};

ExperimentalCost _$ExperimentalCostFromJson(Map<String, dynamic> json) =>
    ExperimentalCost(
      input: (json['input'] as num).toDouble(),
      output: (json['output'] as num).toDouble(),
      cache: CacheCost.fromJson(json['cache'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExperimentalCostToJson(ExperimentalCost instance) =>
    <String, dynamic>{
      'input': instance.input,
      'output': instance.output,
      'cache': instance.cache,
    };

ModelLimit _$ModelLimitFromJson(Map<String, dynamic> json) => ModelLimit(
  context: (json['context'] as num).toInt(),
  input: (json['input'] as num?)?.toInt(),
  output: (json['output'] as num).toInt(),
);

Map<String, dynamic> _$ModelLimitToJson(ModelLimit instance) =>
    <String, dynamic>{
      'context': instance.context,
      'input': instance.input,
      'output': instance.output,
    };

ProviderListResponse _$ProviderListResponseFromJson(
  Map<String, dynamic> json,
) => ProviderListResponse(
  all: (json['all'] as List<dynamic>)
      .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  defaultProvider: Map<String, String>.from(json['default'] as Map),
  connected: (json['connected'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ProviderListResponseToJson(
  ProviderListResponse instance,
) => <String, dynamic>{
  'all': instance.all,
  'default': instance.defaultProvider,
  'connected': instance.connected,
};
