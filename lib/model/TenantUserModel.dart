class TenantUserModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final String userId;
  late final int role;
  DateTime? joinDate;
  String? createBy;
  final int disabled;
  final String username;
  String? avatar;
  String? email;

  TenantUserModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.userId,
    required this.role,
    this.joinDate,
    this.createBy,
    required this.disabled,
    required this.username,
    this.avatar,
    this.email,
  });

  factory TenantUserModel.fromJson(Map<String, dynamic> json) {
    return TenantUserModel(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      tenantName: json['tenantName'] as String? ?? '私人空间',
      userId: json['userId'] as String? ?? '',
      role: json['role'] as int? ?? 0,
      joinDate: json['joinDate'] != "" && json['joinDate'] != null ? DateTime.parse(json['joinDate']) : null,
      createBy: json['createBy'] ?? "",
      disabled: json['disabled'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      avatar: json['avater'] ?? "", // 注意JSON字段名是avater
      email: json['email'] ?? "",
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'userId': userId,
      'role': role,
      'joinDate': joinDate?.toIso8601String(),
      'createBy': createBy,
      'disabled': disabled,
      'username': username,
      'avater': avatar, // 保持与fromJson一致的字段名
      'email': email,
    };
  }
}