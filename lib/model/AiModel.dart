// lib/model/AiModel.dart

class AiModel {
  final String id;
  final String modelName;
  final String type; // online / ollama
  final String baseUrl;
  final String? apiKey;
  final String? companyId;
  final String updateTime;
  final String createTime;

  AiModel({
    required this.id,
    required this.modelName,
    required this.type,
    required this.baseUrl,
    this.apiKey,
    this.companyId,
    required this.updateTime,
    required this.createTime,
  });

  // 工厂模式 - 从 JSON 创建
  factory AiModel.fromJson(Map<String, dynamic> json) {
    return AiModel(
      id: json["id"]?.toString() ?? '',
      modelName: json['modelName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'online',
      baseUrl: json['baseUrl']?.toString() ?? '',
      apiKey: json['apiKey']?.toString(),
      companyId: json['companyId']?.toString(),
      updateTime: json["updateTime"]?.toString() ?? '',
      createTime: json["createTime"]?.toString() ?? '',
    );
  }

  // 转换为 JSON（用于提交）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modelName': modelName,
      'type': type,
      'baseUrl': baseUrl,
      if (apiKey != null && apiKey!.isNotEmpty) 'apiKey': apiKey,
      if (companyId != null && companyId!.isNotEmpty) 'companyId': companyId,
      'updateTime': updateTime,
      'createTime': createTime,
    };
  }

  // 转换为 JSON（用于更新接口，只包含必要字段）
  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      'modelName': modelName,
      'type': type,
      'baseUrl': baseUrl,
      if (apiKey != null && apiKey!.isNotEmpty) 'apiKey': apiKey,
    };
  }

  // 转换为 JSON（用于新增接口）
  Map<String, dynamic> toAddJson() {
    return {
      'modelName': modelName,
      'type': type,
      'baseUrl': baseUrl,
      if (apiKey != null && apiKey!.isNotEmpty) 'apiKey': apiKey,
    };
  }
}