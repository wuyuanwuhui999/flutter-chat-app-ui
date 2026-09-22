class DirectoryModel {
  final String id;
  final String userId;
  final String directory;
  String? tenantId;
  String? updateTime;
  String? createTime;
  bool isSelected;

  DirectoryModel({
    required this.id,
    required this.userId,
    required this.directory,
    this.isSelected = false,
    this.tenantId = "",
    this.updateTime,
    this.createTime,
  });

  /// 【修复】后端字段可能为 null（如 user_id 允许为空），
  /// 直接强转会抛 type 'Null' is not a subtype of type 'String'，这里统一兜底；
  /// 同时修正 tenantId 误取 directory 字段的问题
  factory DirectoryModel.fromJson(Map<String, dynamic> json) {
    return DirectoryModel(
      id: _toStr(json['id']),
      userId: _toStr(json['userId']),
      directory: _toStr(json['directory']),
      tenantId: _toStr(json['tenantId']),
      updateTime: _toStr(json['updateTime']),
      createTime: _toStr(json['createTime']),
    );
  }

  /// 安全转换字符串：null 转为空串，避免类型转换异常
  static String _toStr(dynamic value) => value?.toString() ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'directory': directory,
      'tenantId':tenantId,
      'updateTime': updateTime,
      'createTime': createTime,
    };
  }

  @override
  String toString() {
    return 'DirectoryModel{id: $id, userId: $userId, directory: $directory, tenantId: $tenantId, updateTime: $updateTime, createTime: $createTime}';
  }
} 
