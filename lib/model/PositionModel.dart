// lib/model/PositionModel.dart

/// @author: wuwenqiang
/// @description: 职位模型
/// @date: 2026-07-25
class PositionModel {
  final String id;
  final String positionName;
  final String departmentId;
  final String? description;
  final String? createTime;

  PositionModel({
    required this.id,
    required this.positionName,
    required this.departmentId,
    this.description,
    this.createTime,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'] as String? ?? '',
      positionName: json['positionName'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      description: json['description'] as String?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'positionName': positionName,
      'departmentId': departmentId,
      'description': description,
      'createTime': createTime,
    };
  }
}