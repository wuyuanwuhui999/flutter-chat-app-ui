class TenantModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int status;
  final int role;  // ✅ 新增：用户在该租户中的角色
  final DateTime? createDate;
  final DateTime? updateDate;
  final String? createdBy;
  final String? updatedBy;

  TenantModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.status,
    required this.role,
    this.createDate,
    this.updateDate,
    this.createdBy,
    this.updatedBy,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      status: json['status'] as int,
      role: json['role'] as int? ?? 0,
      createDate: json['createDate'] != null ? DateTime.parse(json['createDate'] as String) : null,
      updateDate: json['updateDate'] != null ? DateTime.parse(json['updateDate'] as String) : null,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'status': status,
      'role': role,
      'createDate': createDate?.toIso8601String(),
      'updateDate': updateDate?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  @override
  String toString() {
    return 'TenantModel{id: $id, name: $name, code: $code, description: $description, status: $status, role: $role, createDate: $createDate, updateDate: $updateDate, createdBy: $createdBy, updatedBy: $updatedBy}';
  }

  // 状态相关方法
  static const int STATUS_ACTIVE = 1;
  static const int STATUS_INACTIVE = 0;

  bool get isActive => status == STATUS_ACTIVE;
  String get statusText => isActive ? '启用' : '禁用';

  // ✅ 角色判断方法
  bool get isAdmin => role == 1;
  bool get isOwner => role == 2;
  String get roleText {
    switch (role) {
      case 0:
        return '普通成员';
      case 1:
        return '管理员';
      case 2:
        return '超级管理员';
      default:
        return '未知';
    }
  }
}