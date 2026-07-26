import '../utils/common.dart';

class ChatHistoryModel {
  final int id;  // ✅ 保持 int（后端是 Integer）
  final String modelId;  // ✅ 改为 String（后端是 String(64)）
  final String userId;
  final String? files;
  final String chatId;
  final String prompt;
  final String content;
  final String createTime;
  final String? thinkContent;
  final String? responseContent;
  final String timeAgo;

  ChatHistoryModel({
    required this.id,
    required this.modelId,
    required this.userId,
    this.files,
    required this.chatId,
    required this.prompt,
    required this.content,
    required this.createTime,
    this.thinkContent,
    this.responseContent,
    required this.timeAgo,
  });

  // 工厂模式 - 从 JSON 创建
  factory ChatHistoryModel.fromJson(Map<String, dynamic> json) {
    return ChatHistoryModel(
      id: json["id"] as int? ?? 0,
      modelId: json["modelId"]?.toString() ?? '',  // ✅ String 类型
      userId: json["userId"]?.toString() ?? '',
      files: json["files"]?.toString(),
      chatId: json["chatId"]?.toString() ?? '',
      prompt: json["prompt"]?.toString() ?? '',
      content: json["content"]?.toString() ?? '',
      thinkContent: json["thinkContent"]?.toString(),
      responseContent: json["responseContent"]?.toString(),
      timeAgo: formatTimeAgo(json["createTime"]?.toString() ?? ''),
      createTime: json["createTime"]?.toString() ?? '',
    );
  }
}