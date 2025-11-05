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
    required this.checked
  });
  //工厂模式-用这种模式可以省略New关键字
  factory DocModel.fromJson(dynamic json){
    return DocModel(
        id:json['id'],
        tenantId:json['tenantId'],
        directoryId: json['directoryId'],
        directoryName: json['directoryName'],
        name:json['name'],
        ext:json['ext'],
        userId:json['userId'],
        createTime:json['createTime'],
        updateTime:json['updateTime'],
        checked: json['checked']??false
    );
  }
}