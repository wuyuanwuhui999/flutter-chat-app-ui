// lib/model/CompanyModel.dart

/// 公司信息模型
class CompanyModel {
  final String id;
  final String name;
  final String code;
  final int role;
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
    return 'CompanyModel{id: $id, name: $name, code: $code, role: $role, status: $status}';
  }
}