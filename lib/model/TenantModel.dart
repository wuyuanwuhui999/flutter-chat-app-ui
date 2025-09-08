class TenantModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int status;
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
    this.createDate,
    this.updateDate,
    required this.createdBy,
    this.updatedBy,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      status: json['status'] as int,
      createDate: json['updateDate'] != null ? DateTime.parse(json['createDate'] as String) : null,
      updateDate: json['updateDate'] != null ? DateTime.parse(json['updateDate'] as String) : null,
      createdBy: json['createdBy'] as String,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  @override
  String toString() {
    return 'TenantModel{id: $id, name: $name, code: $code, description: $description, status: $status, createDate: $createDate, updateDate: $updateDate, createdBy: $createdBy, updatedBy: $updatedBy}';
  }

  // 状态相关方法
  static const int STATUS_ACTIVE = 1;
  static const int STATUS_INACTIVE = 0;

  bool get isActive => status == STATUS_ACTIVE;

  String get statusText => isActive ? '启用' : '禁用';
}