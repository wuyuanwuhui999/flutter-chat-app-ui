import '../model/UserInfoModel.dart';

/// @author: wuwenqiang
/// @description: 搜索用户模型 - 继承 UserInfoModel，增加 checked 字段
/// @date: 2026-07-25
class SearchUserModel extends UserInfoModel {
  @override
  int? checked; // 0: 不在该公司, 1: 已在该公司

  SearchUserModel({
    required super.id,
    super.avater,
    super.birthday,
    required super.createDate,
    super.email,
    super.role,
    super.sex,
    super.telephone,
    required super.updateDate,
    required super.userAccount,
    required super.username,
    super.sign,
    super.region,
    super.disabled,
    super.permission,
    this.checked = 0,
  });

  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    // 安全转换 checked 字段，支持 String 或 int 类型
    int? parseChecked(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return SearchUserModel(
      id: json["id"]?.toString() ?? '',
      avater: json["avater"]?.toString(),
      birthday: json["birthday"]?.toString(),
      createDate: json["createDate"]?.toString() ?? '',
      email: json["email"]?.toString(),
      role: json["role"]?.toString(),
      sex: json["sex"] is int ? json["sex"] : int.tryParse(json["sex"]?.toString() ?? ''),
      telephone: json["telephone"]?.toString(),
      updateDate: json["updateDate"]?.toString() ?? '',
      userAccount: json["userAccount"]?.toString() ?? '',
      username: json["username"]?.toString() ?? '',
      sign: json["sign"]?.toString(),
      region: json["region"]?.toString(),
      disabled: json["disabled"] is int ? json["disabled"] : int.tryParse(json["disabled"]?.toString() ?? ''),
      permission: json["permission"] is int ? json["permission"] : int.tryParse(json["permission"]?.toString() ?? ''),
      checked: parseChecked(json["checked"]),
    );
  }
}