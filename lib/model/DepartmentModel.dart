/// @author: wuwenqiang
/// @description: 部门模型
/// @date: 2026-07-25
class DepartmentModel {
  final String id;
  final String companyId;
  final String departmentName;
  final String? description;
  final String? createTime;

  DepartmentModel({
    required this.id,
    required this.companyId,
    required this.departmentName,
    this.description,
    this.createTime,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      description: json['description'] as String?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'departmentName': departmentName,
      'description': description,
      'createTime': createTime,
    };
  }
}