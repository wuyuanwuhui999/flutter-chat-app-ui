class UserInfoModel {
  String id;
  String? avater;
  String? birthday;
  String createDate;
  String? email;
  String? role;
  int? sex;
  String? telephone;
  String updateDate;
  String userAccount;
  String username;
  String? sign;
  String? region;
  int? disabled;
  int? permission;
  int? checked;

  UserInfoModel({
    required this.id,
    this.avater,
    this.birthday,
    required this.createDate,
    this.email,
    this.role,
    this.sex,
    this.telephone,
    required this.updateDate,
    required this.userAccount,
    required this.username,
    this.sign,
    this.region,
    this.disabled,
    this.permission,
    this.checked,
  });

  /// 安全转换为 int? 的辅助方法
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // 处理空字符串
      if (value.isEmpty) return null;
      // 尝试解析为数字
      return int.tryParse(value);
    }
    return null;
  }

  /// 安全转换为 String? 的辅助方法
  static String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  // 工厂模式 - 用这种模式可以省略New关键字
  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: _toString(json["id"]) ?? '',
      avater: _toString(json["avater"]),
      birthday: _toString(json["birthday"]),
      createDate: _toString(json["createDate"]) ?? '',
      email: _toString(json["email"]),
      role: _toString(json["role"]),
      sex: _toInt(json["sex"]),
      telephone: _toString(json["telephone"]),
      updateDate: _toString(json["updateDate"]) ?? '',
      userAccount: _toString(json["userAccount"]) ?? '',
      username: _toString(json["username"]) ?? '',
      sign: _toString(json["sign"]),
      region: _toString(json["region"]),
      disabled: _toInt(json["disabled"]),
      permission: _toInt(json["permission"]),
      checked: _toInt(json["checked"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "avater": avater,
      "birthday": birthday,
      "createDate": createDate,
      "email": email,
      "role": role,
      "sex": sex,
      "telephone": telephone,
      "updateDate": updateDate,
      "userAccount": userAccount,
      "username": username,
      "sign": sign,
      "region": region,
      "checked": checked,
    };
  }
}