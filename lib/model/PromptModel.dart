/// @author: wuwenqiang
/// @description: 提示词模型
/// @date: 2026-09-11
class PromptModel {
  String id;
  String tenantId;
  String userId;
  String prompt;
  String? createTime;
  String? updateTime;

  PromptModel({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.prompt,
    this.createTime,
    this.updateTime,
  });

  /// 工厂模式 - 从 JSON 创建
  factory PromptModel.fromJson(Map<String, dynamic> json) {
    return PromptModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      createTime: json['createTime']?.toString(),
      updateTime: json['updateTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'userId': userId,
      'prompt': prompt,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }
}