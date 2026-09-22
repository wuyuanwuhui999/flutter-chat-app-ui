class DocModel{
  String id;// 文档id
  String tenantId; // 租户id
  String directoryId;// 目录id
  String directoryName;// 文件夹名称（getDocListByDirId 接口不返回该字段，可能为空）
  String name; // 文档名称
  String ext; // 文档格式
  String userId;// 用户id
  String createTime;//创建时间
  String updateTime;// 更新时间
  String permission;// 文档权限：private-私密，tenant-租户内公开，company-公司内公开
  bool checked;
  DocModel({
    required this.id,
    required this.tenantId,
    required this.directoryId,
    required this.directoryName,
    required this.name,
    required this.ext,
    required this.userId,
    required this.createTime,
    required this.updateTime,
    required this.checked,
    this.permission = 'private'
  });
  //工厂模式-用这种模式可以省略New关键字
  /// 【修复】后端 getDocListByDirId 是 SELECT * FROM chat_doc，不含 directory_name 列，
  /// 部分字段（directoryName/permission/createTime 等）可能为 null，
  /// 直接强转非空 String 会抛 type 'Null' is not a subtype of type 'String'，
  /// 这里统一做空值兜底
  factory DocModel.fromJson(dynamic json){
    return DocModel(
        id: _toStr(json['id']),
        tenantId: _toStr(json['tenantId']),
        directoryId: _toStr(json['directoryId']),
        directoryName: _toStr(json['directoryName']),
        name: _toStr(json['name']),
        ext: _toStr(json['ext']),
        userId: _toStr(json['userId']),
        createTime: _toStr(json['createTime']),
        updateTime: _toStr(json['updateTime']),
        permission: _toStr(json['permission']).isEmpty
            ? 'private'
            : _toStr(json['permission']),
        checked: json['checked'] ?? false
    );
  }

  /// 安全转换字符串：null 转为空串，避免类型转换异常
  static String _toStr(dynamic value) => value?.toString() ?? '';
}
