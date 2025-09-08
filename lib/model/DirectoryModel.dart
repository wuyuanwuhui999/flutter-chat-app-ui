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

  factory DirectoryModel.fromJson(Map<String, dynamic> json) {
    return DirectoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      directory: json['directory'] as String,
      tenantId: json['directory'],
      updateTime: json['updateTime'],
      createTime: json['createTime'],
    );
  }

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