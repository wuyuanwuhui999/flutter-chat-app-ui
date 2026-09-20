import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/service/serverMethod.dart';
import 'package:flutter_chat_app/utils/HttpUtil.dart';

/// 真实起本地 HTTP 服务，抓取实际发出的请求行（方法/路径/查询参数），
/// 验证修改权限、删除文档、按目录查询文档三个接口的调用方式
void main() {
  late HttpServer server;
  final List<String> requestLines = <String>[];
  bool failUpdatePermission = false;

  setUp(() async {
    requestLines.clear();
    failUpdatePermission = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest req) async {
      requestLines.add('${req.method} ${req.uri.path}?${req.uri.query}');
      final String path = req.uri.path;

      String body;
      if (path.startsWith('/service/chat/updateDocPermission/')) {
        body = failUpdatePermission
            ? jsonEncode({'status': 'FAIL', 'msg': '文档不存在或无权修改', 'data': null})
            : jsonEncode({'status': 'SUCCESS', 'data': 1, 'msg': '文档权限更新成功'});
      } else if (path.startsWith('/service/chat/deleteDoc/')) {
        body = jsonEncode({'status': 'SUCCESS', 'data': 1, 'msg': '文档删除成功'});
      } else if (path == '/service/chat/getDocListByDirId') {
        body = jsonEncode({
          'status': 'SUCCESS',
          'data': [
            {
              'id': 'doc-1',
              'tenantId': 't1',
              'directoryId': 'dir-1',
              'directoryName': '工作资料',
              'name': '需求文档.pdf',
              'ext': 'pdf',
              'userId': 'u1',
              'permission': 'private',
            },
          ],
        });
      } else {
        body = jsonEncode({'status': 'FAIL', 'msg': '未知接口', 'data': null});
      }

      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(body);
      await req.response.close();
    });

    final httpUtil = HttpUtil.getInstance();
    httpUtil.setToken('test-token');
    httpUtil.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('修改文档权限：PUT /service/chat/updateDocPermission/{docId}?permission=xxx', () async {
    final res = await updateDocPermissionService('doc-1', 'company');
    expect(requestLines.single,
        'PUT /service/chat/updateDocPermission/doc-1?permission=company');
    // data大于0表示修改成功
    expect(int.parse(res.data.toString()) > 0, isTrue);
    expect(res.msg, '文档权限更新成功');
  });

  test('删除文档：DELETE /service/chat/deleteDoc/{docId}', () async {
    final res = await deleteMyDocumentService('doc-9');
    expect(requestLines.single, 'DELETE /service/chat/deleteDoc/doc-9?');
    expect(int.parse(res.data.toString()) > 0, isTrue);
    expect(res.msg, '文档删除成功');
  });

  test('修改权限失败时，异常里能取到后端返回的msg', () async {
    failUpdatePermission = true;
    try {
      await updateDocPermissionService('doc-1', 'private');
      fail('接口返回FAIL时应该抛出异常');
    } catch (e) {
      expect(parseResponseErrorMsg(e), '文档不存在或无权修改');
    }
  });

  test('按目录查文档：GET /service/chat/getDocListByDirId?tenantId=&directoryId=', () async {
    final res = await getDocListByDirIdService('t1', 'dir-1');
    expect(requestLines.single,
        'GET /service/chat/getDocListByDirId?tenantId=t1&directoryId=dir-1');
    expect(res.data.length, 1);
    // 文档权限字段已解析
    expect(res.data.first['permission'], 'private');
  });
}
