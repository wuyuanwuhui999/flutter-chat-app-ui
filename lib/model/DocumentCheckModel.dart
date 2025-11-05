import 'DocModel.dart';

class DocumentCheckModel{
  String directoryName;// 文档id
  bool expand;
  String directoryId;
  List<DocModel>docList;
  DocumentCheckModel({
    required this.expand,
    required this.directoryId,
    required this.directoryName,
    required this.docList,
  });
  //工厂模式-用这种模式可以省略New关键字
  factory DocumentCheckModel.fromJson(dynamic json){
    return DocumentCheckModel(
        expand:json['expand'],
        directoryId: json["directoryId"],
        directoryName:json['directoryName'],
        docList: json['docList']
    );
  }
}