// lib/model/CompanyModel.dart

/// 公司信息模型
class CompanyModel {
  final String id;
  final String name;
  final String code;
  final int role;  // 用户在该公司的角色：0普通用户，1管理员，2超级管理员
  final String? positionId; // 职务ID
  final String? description;
  final int status;
  final String createDate;
  final String updateDate;
  final String createdBy;
  final String? updatedBy;

  CompanyModel({
    required this.id,
    required this.name,
    required this.code,
    required this.role,
    this.positionId,
    this.description,
    required this.status,
    required this.createDate,
    required this.updateDate,
    required this.createdBy,
    this.updatedBy,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      role: json['role'] as int? ?? 0,
      positionId: json['positionId'] as String?,
      description: json['description'] as String?,
      status: json['status'] as int? ?? 0,
      createDate: json['createDate'] as String? ?? '',
      updateDate: json['updateDate'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'role': role,
      'positionId': positionId,
      'description': description,
      'status': status,
      'createDate': createDate,
      'updateDate': updateDate,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  @override
  String toString() {
    return 'CompanyModel{id: $id, name: $name, code: $code, role: $role, positionId: $positionId, status: $status}';
  }

  // 判断是否为管理员（role > 0）
  bool get isAdmin => role > 0;
  // 判断是否为超级管理员
  bool get isSuperAdmin => role >= 2;
}