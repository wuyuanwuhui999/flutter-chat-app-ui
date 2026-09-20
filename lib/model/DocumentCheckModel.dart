import 'DocModel.dart';

/// @author: wuwenqiang
/// @description: 文档目录分组模型（目录 + 展开状态 + 该目录下按需加载的文档列表）
/// @date: 2026-09-20
class DocumentCheckModel {
  /// 目录名称
  String directoryName;

  /// 是否展开（展开后才加载该目录下的文档列表）
  bool expand;

  /// 目录id
  String directoryId;

  /// 目录下的文档列表
  List<DocModel> docList;

  /// 是否正在加载该目录下的文档
  bool loading;

  /// 是否已经加载过该目录下的文档（避免重复请求接口）
  bool loaded;

  DocumentCheckModel({
    required this.expand,
    required this.directoryId,
    required this.directoryName,
    required this.docList,
    this.loading = false,
    this.loaded = false,
  });

  //工厂模式-用这种模式可以省略New关键字
  factory DocumentCheckModel.fromJson(dynamic json) {
    return DocumentCheckModel(
        expand: json['expand'] ?? false,
        directoryId: json["directoryId"],
        directoryName: json['directoryName'],
        docList: json['docList'] ?? <DocModel>[]);
  }
}
