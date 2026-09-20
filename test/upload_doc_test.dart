import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/utils/HttpUtil.dart';

/// 真实起一个本地 HTTP 服务，抓取 uploadDoc 实际发出的请求（URL + multipart 字段）
void main() {
  late HttpServer server;
  final List<String> requestPaths = <String>[];
  final List<String> requestBodies = <String>[];

  setUp(() async {
    requestPaths.clear();
    requestBodies.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest req) async {
      requestPaths.add(req.uri.path);
      requestBodies.add(await utf8.decoder.bind(req).join());
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write('{"status":"SUCCESS","data":null,"msg":null,"total":null,"token":null}');
      await req.response.close();
    });
    final httpUtil = HttpUtil.getInstance();
    httpUtil.setToken('test-token');
    httpUtil.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  tearDown(() async {
    await server.close(force: true);
  });

  File buildTempFile() {
    final file = File('${Directory.systemTemp.path}/flutter_upload_test.txt');
    file.writeAsStringSync('hello world');
    return file;
  }

  test('uploadDoc：地址不带 tenantId/directoryId，参数放在body中（fixed带chunkSize）', () async {
    final res = await HttpUtil.getInstance().uploadDoc(
      filePath: buildTempFile().path,
      fileName: 'flutter_upload_test.txt',
      tenantId: 'tenant-1',
      directoryId: 'dir-1',
      permission: 'tenant',
      splitMethod: 'fixed',
      chunkSize: 800,
    );

    expect(res.status, 'SUCCESS');
    // 接口地址已经去掉 {tenantId}/{directoryId}
    expect(requestPaths.single, '/service/chat/uploadDoc');

    final body = requestBodies.single;
    // 文件字段
    expect(body.contains('name="file"'), isTrue);
    expect(body.contains('filename="flutter_upload_test.txt"'), isTrue);
    // body 参数
    expect(body.contains('name="tenantId"'), isTrue);
    expect(body.contains('name="directoryId"'), isTrue);
    expect(body.contains('name="permission"'), isTrue);
    expect(body.contains('name="splitMethod"'), isTrue);
    expect(body.contains('name="chunkSize"'), isTrue);
    expect(body.contains('tenant-1'), isTrue);
    expect(body.contains('dir-1'), isTrue);
    expect(body.contains('tenant'), isTrue);
    expect(body.contains('fixed'), isTrue);
    expect(body.contains('800'), isTrue);
  });

  test('uploadDoc：非fixed分割方式不下发chunkSize', () async {
    await HttpUtil.getInstance().uploadDoc(
      filePath: buildTempFile().path,
      fileName: 'flutter_upload_test.txt',
      tenantId: 'tenant-2',
      directoryId: 'dir-2',
      permission: 'private',
      splitMethod: 'recursive',
      chunkSize: 1000,
    );

    expect(requestPaths.single, '/service/chat/uploadDoc');
    final body = requestBodies.single;
    expect(body.contains('name="chunkSize"'), isFalse);
    expect(body.contains('name="splitMethod"'), isTrue);
    expect(body.contains('recursive'), isTrue);
    expect(body.contains('name="permission"'), isTrue);
    expect(body.contains('private'), isTrue);
  });
}
