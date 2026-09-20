class DocModel{
  String id;// 文档id
  String tenantId; // 租户id
  String directoryId;// 目录id
  String directoryName;// 文件夹名称
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
  factory DocModel.fromJson(dynamic json){
    return DocModel(
        id:json['id'],
        tenantId:json['tenantId'],
        directoryId: json['directoryId'],
        directoryName:json['directoryName'],
        name:json['name'],
        ext:json['ext'],
        userId:json['userId'],
        createTime:json['createTime'],
        updateTime:json['updateTime'],
        permission: json['permission'] ?? 'private',
        checked: json['checked']??false
    );
  }
}