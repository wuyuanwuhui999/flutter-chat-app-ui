import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/model/DirectoryModel.dart';
import 'package:flutter_chat_app/model/DocModel.dart';

/// 回归测试：后端部分接口（如 getDocListByDirId 的 SELECT * FROM chat_doc）
/// 不返回 directory_name 列，字段可能为 null，解析时不能抛
/// type 'Null' is not a subtype of type 'String'
void main() {
  test('DocModel.fromJson：字段为null时兜底，不抛异常', () {
    final DocModel doc = DocModel.fromJson({
      'id': 'doc-3',
      'tenantId': 't1',
      'directoryId': 'dir-2',
      'directoryName': null,
      'name': '学习笔记.txt',
      'ext': 'txt',
      'userId': null,
      'createTime': null,
      'updateTime': null,
      'permission': null,
    });

    expect(doc.id, 'doc-3');
    expect(doc.name, '学习笔记.txt');
    expect(doc.directoryName, '');
    expect(doc.userId, '');
    expect(doc.createTime, '');
    // 权限为空时默认私密
    expect(doc.permission, 'private');
    expect(doc.checked, isFalse);
  });

  test('DocModel.fromJson：字段缺失时同样兜底', () {
    final DocModel doc = DocModel.fromJson({'id': 'doc-4', 'name': 'a.pdf'});
    expect(doc.ext, '');
    expect(doc.directoryName, '');
    expect(doc.permission, 'private');
  });

  test('DirectoryModel.fromJson：user_id为null时兜底，tenantId取tenantId字段', () {
    final DirectoryModel dir = DirectoryModel.fromJson({
      'id': 'dir-1',
      'userId': null,
      'directory': '工作资料',
      'tenantId': 't1',
      'updateTime': null,
      'createTime': null,
    });

    expect(dir.id, 'dir-1');
    expect(dir.directory, '工作资料');
    expect(dir.userId, '');
    expect(dir.tenantId, 't1');
  });
}
