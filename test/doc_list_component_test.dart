import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_chat_app/component/DocumentListComponent.dart';
import 'package:flutter_chat_app/model/CompanyModel.dart';
import 'package:flutter_chat_app/model/TenantModel.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/utils/HttpUtil.dart';

/// 通过替换 dio 的 HttpClientAdapter 来模拟后端，验证文档列表组件：
/// 目录按需加载、箭头旋转、三个点操作（修改权限/删除）、我的文档模式
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.requestLog);

  /// 请求记录：'METHOD path?query body'
  final List<String> requestLog;

  /// 是否让修改权限接口返回失败
  bool failUpdatePermission = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    String body = '';
    if (requestStream != null) {
      final List<int> bytes = <int>[];
      await for (final Uint8List chunk in requestStream) {
        bytes.addAll(chunk);
      }
      body = utf8.decode(bytes, allowMalformed: true);
    }
    requestLog.add(
      '${options.method} ${options.uri.path}?${options.uri.query} $body',
    );
    return ResponseBody.fromString(
      _route(options.uri.path, options.uri.query),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  String _route(String path, String query) {
    if (path == '/service/chat/getDirectoryList') {
      return jsonEncode({
        'status': 'SUCCESS',
        'data': [
          {'id': 'dir-1', 'userId': 'u1', 'tenantId': 't1', 'directory': '工作资料'},
          {'id': 'dir-2', 'userId': 'u1', 'tenantId': 't1', 'directory': '学习资料'},
        ],
      });
    }
    if (path == '/service/chat/getDocListByDirId') {
      if (query.contains('directoryId=dir-1')) {
        return jsonEncode({
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
              'createTime': '2026-09-01 10:00:00',
              'updateTime': '2026-09-01 10:00:00',
              'permission': 'tenant',
            },
            {
              'id': 'doc-2',
              'tenantId': 't1',
              'directoryId': 'dir-1',
              'directoryName': '工作资料',
              'name': '周报.txt',
              'ext': 'txt',
              'userId': 'u1',
              'createTime': '2026-09-02 10:00:00',
              'updateTime': '2026-09-02 10:00:00',
              'permission': 'company',
            },
          ],
        });
      }
      if (query.contains('directoryId=dir-2')) {
        // 复现后端 getDocListByDirId（SELECT * FROM chat_doc）不返回 directory_name 的场景：
        // directoryName / permission / createTime / userId 均为 null，解析时不能崩
        return jsonEncode({
          'status': 'SUCCESS',
          'data': [
            {
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
            },
          ],
        });
      }
      return jsonEncode({'status': 'SUCCESS', 'data': []});
    }
    if (path == '/service/chat/getPublicDocList') {
      // 公开文档接口一次性返回全部文档，带 directoryName 目录名称字段
      return jsonEncode({
        'status': 'SUCCESS',
        'data': [
          {
            'id': 'pub-1',
            'tenantId': 't1',
            'companyId': 'c1',
            'directoryId': 'dir-9',
            'directoryName': '公司共享',
            'name': '公开制度.pdf',
            'ext': 'pdf',
            'userId': 'other-user',
            'permission': 'company',
          },
          {
            'id': 'pub-2',
            'tenantId': 't1',
            'companyId': 'c1',
            'directoryId': 'dir-8',
            'directoryName': '培训资料',
            'name': '培训资料.txt',
            'ext': 'txt',
            'userId': 'other-user',
            'permission': 'tenant',
          },
        ],
      });
    }
    if (path == '/service/chat/updateDocPermission') {
      return failUpdatePermission
          ? jsonEncode({'status': 'FAIL', 'msg': '文档不存在或无权修改', 'data': null})
          : jsonEncode({'status': 'SUCCESS', 'data': 1, 'msg': '文档权限更新成功'});
    }
    if (path.startsWith('/service/chat/deleteDoc/')) {
      return jsonEncode({'status': 'SUCCESS', 'data': 1, 'msg': '文档删除成功'});
    }
    return jsonEncode({'status': 'FAIL', 'msg': '未知接口', 'data': null});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late _FakeHttpClientAdapter adapter;
  final List<String> requestLog = <String>[];

  setUp(() {
    requestLog.clear();
    adapter = _FakeHttpClientAdapter(requestLog);
    final httpUtil = HttpUtil.getInstance();
    httpUtil.setToken('test-token');
    httpUtil.dio.options.baseUrl = 'http://127.0.0.1:4000';
    httpUtil.dio.httpClientAdapter = adapter;
  });

  Widget buildWidget({
    bool showCheckbox = true,
    bool showBottomButtons = true,
    bool publicMode = false,
    Function(List<String>, List<String>)? onConfirm,
  }) {
    final chatProvider = ChatProvider();
    chatProvider.setCurrentTenant(
      TenantModel(id: 't1', name: '测试租户', code: 'T1', status: 1, role: 1),
    );
    chatProvider.setCurrentCompany(CompanyModel(
      id: 'c1',
      name: '测试公司',
      code: 'C1',
      role: 1,
      status: 1,
      createDate: '2026-09-01',
      updateDate: '2026-09-01',
      createdBy: 'u1',
    ));
    return ChangeNotifierProvider<ChatProvider>.value(
      value: chatProvider,
      child: MaterialApp(
        home: Scaffold(
          body: DocumentListComponent(
            showCheckbox: showCheckbox,
            showBottomButtons: showBottomButtons,
            publicMode: publicMode,
            onConfirm: onConfirm,
          ),
        ),
      ),
    );
  }

  /// 展开/收起目录
  Future<void> tapDirectory(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  /// 旋转矩阵 entry(0,0)=cos(角度)：折叠0度=1，展开顺时针90度=0
  double arrowAngle(WidgetTester tester, String directoryId) {
    final Transform transform = tester.widget<Transform>(
      find.byKey(ValueKey('dir-arrow-$directoryId')),
    );
    return transform.transform.entry(0, 0);
  }

  /// 限定在对话框内部的文案（避免与文档列表底部按钮重名）
  Finder inDialog(String text) => find.descendant(
        of: find.byType(Dialog),
        matching: find.text(text),
      );

  testWidgets('需求2：先获取目录，点击目录才加载文档，箭头展开转90度、收起还原', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // 只请求目录列表，未请求任何文档列表
    expect(requestLog.length, 1);
    expect(requestLog.first, contains('GET /service/chat/getDirectoryList'));
    expect(requestLog.first, contains('tenantId=t1'));
    // 只显示后端返回的目录，不再有本地拼装的"默认文件夹"
    expect(find.text('默认文件夹'), findsNothing);
    expect(find.text('工作资料'), findsOneWidget);
    expect(find.text('学习资料'), findsOneWidget);
    // 未展开：不显示文档，箭头向右（0度）
    expect(find.text('需求文档.pdf'), findsNothing);
    expect(arrowAngle(tester, 'dir-1'), closeTo(1, 0.0001));

    // 点击目录名称 -> 加载该目录文档
    await tapDirectory(tester, '工作资料');
    expect(requestLog.length, 2);
    expect(requestLog[1], contains('GET /service/chat/getDocListByDirId'));
    expect(requestLog[1], contains('tenantId=t1'));
    expect(requestLog[1], contains('directoryId=dir-1'));
    expect(find.text('需求文档.pdf'), findsOneWidget);
    expect(find.text('周报.txt'), findsOneWidget);
    // 展开：箭头顺时针旋转90度（cos90=0）
    expect(arrowAngle(tester, 'dir-1'), closeTo(0, 0.0001));

    // 再次点击目录名称 -> 收起，箭头还原，不重复请求
    await tapDirectory(tester, '工作资料');
    expect(find.text('需求文档.pdf'), findsNothing);
    expect(arrowAngle(tester, 'dir-1'), closeTo(1, 0.0001));
    expect(requestLog.length, 2);

    // 再次展开：已加载过，不重复请求
    await tapDirectory(tester, '工作资料');
    expect(find.text('需求文档.pdf'), findsOneWidget);
    expect(requestLog.length, 2);

    // 展开另一个目录：按目录id请求
    await tapDirectory(tester, '学习资料');
    expect(requestLog.length, 3);
    expect(requestLog[2], contains('directoryId=dir-2'));
    expect(arrowAngle(tester, 'dir-2'), closeTo(0, 0.0001));
  });

  testWidgets('回归：后端不返回 directoryName/permission 等字段时不能抛异常', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // 目录下文档的 directoryName/permission/createTime/userId 均为 null
    await tapDirectory(tester, '学习资料');
    expect(find.text('学习笔记.txt'), findsOneWidget);
    // 解析失败时列表会走"暂无文档"分支，这里不允许出现
    expect(find.text('暂无文档'), findsNothing);

    // 权限为 null 时默认私密
    await tester.tap(find.byKey(const ValueKey('doc-more-doc-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改权限'));
    await tester.pumpAndSettle();
    expect(inDialog('私密'), findsOneWidget);
    await tester.tap(inDialog('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('需求3+4：三个点 -> 修改权限，权限默认回显permission，确定调用updateDocPermission', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();
    await tapDirectory(tester, '工作资料');

    // 文档条目已去掉时间，右侧为三个点操作图标
    expect(find.textContaining('分钟前'), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNWidgets(2));

    // 点击三个点 -> 弹出"修改权限/删除"
    await tester.tap(find.byKey(const ValueKey('doc-more-doc-1')));
    await tester.pumpAndSettle();
    expect(find.text('修改权限'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    // 修改权限 -> 对话框权限下拉默认回显 doc-1 的 permission=tenant（租户内公开）
    await tester.tap(find.text('修改权限'));
    await tester.pumpAndSettle();
    expect(inDialog('权限'), findsOneWidget);
    expect(inDialog('租户内公开'), findsOneWidget);
    expect(inDialog('确定'), findsOneWidget);
    expect(inDialog('取消'), findsOneWidget);
    // 下拉选项为 DOC_PERMISSION_OPTIONS
    await tester.tap(inDialog('租户内公开'));
    await tester.pumpAndSettle();
    expect(find.text('私密'), findsOneWidget);
    expect(find.text('公司内公开'), findsOneWidget);
    await tester.tap(find.text('公司内公开'));
    await tester.pumpAndSettle();
    expect(inDialog('公司内公开'), findsOneWidget);

    // 确定 -> PUT /service/chat/updateDocPermission（docId和permission以JSON放body中）
    await tester.tap(inDialog('确定'));
    await tester.pumpAndSettle();
    expect(requestLog.length, 3);
    expect(requestLog[2], contains('PUT /service/chat/updateDocPermission?'));
    expect(requestLog[2], isNot(contains('/updateDocPermission/')));
    expect(requestLog[2], contains('"docId":"doc-1"'));
    expect(requestLog[2], contains('"permission":"company"'));
    // 修改成功：对话框已关闭（失败时会保留对话框）
    expect(find.byType(Dialog), findsNothing);

    // 成功后列表已回显新权限：再次打开修改权限对话框显示"公司内公开"
    await tester.tap(find.byKey(const ValueKey('doc-more-doc-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改权限'));
    await tester.pumpAndSettle();
    expect(inDialog('公司内公开'), findsOneWidget);
    // 取消关闭，不产生请求
    await tester.tap(inDialog('取消'));
    await tester.pumpAndSettle();
    expect(requestLog.length, 3);
  });

  testWidgets('需求4：修改权限接口失败时提示后端msg且不关闭对话框', (tester) async {
    adapter.failUpdatePermission = true;
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();
    await tapDirectory(tester, '工作资料');

    await tester.tap(find.byKey(const ValueKey('doc-more-doc-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改权限'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('确定'));
    await tester.pumpAndSettle();

    expect(requestLog.last, contains('PUT /service/chat/updateDocPermission?'));
    expect(requestLog.last, contains('"docId":"doc-1"'));
    expect(requestLog.last, contains('"permission":"tenant"'));
    // 失败时对话框保留（未返回新权限），权限未变化
    expect(find.byType(Dialog), findsOneWidget);
    expect(inDialog('租户内公开'), findsOneWidget);
    await tester.tap(inDialog('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('需求5：三个点 -> 删除 -> 确认对话框 -> 调用deleteDoc并移除条目', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();
    await tapDirectory(tester, '工作资料');

    await tester.tap(find.byKey(const ValueKey('doc-more-doc-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    // 确认对话框
    expect(find.text('是否删除文档：周报.txt'), findsOneWidget);

    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(requestLog.length, 3);
    expect(requestLog[2], contains('DELETE /service/chat/deleteDoc/doc-2'));
    // 删除成功后条目从列表移除
    expect(find.text('周报.txt'), findsNothing);
    expect(find.text('需求文档.pdf'), findsOneWidget);
  });

  testWidgets('需求1：我的文档模式无复选框和确定/取消按钮', (tester) async {
    await tester.pumpWidget(
      buildWidget(showCheckbox: false, showBottomButtons: false),
    );
    await tester.pumpAndSettle();
    // 没有底部确定/取消按钮
    expect(find.text('确定'), findsNothing);
    expect(find.text('取消'), findsNothing);
    await tapDirectory(tester, '工作资料');
    expect(find.text('需求文档.pdf'), findsOneWidget);
    // 三个点操作图标仍在，但没有复选框和全选
    expect(find.byIcon(Icons.more_horiz), findsNWidgets(2));
    expect(find.text('全选'), findsNothing);
    expect(find.byKey(const ValueKey('doc-check-doc-1')), findsNothing);
  });

  testWidgets('需求1：选择文档模式有复选框和确定/取消按钮，勾选后确定回调', (tester) async {
    final List<List<String>> confirmed = <List<String>>[];
    await tester.pumpWidget(
      buildWidget(onConfirm: (ids, names) => confirmed.add(ids)),
    );
    await tester.pumpAndSettle();
    expect(find.text('确定'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    // 目录未展开时没有全选
    expect(find.text('全选'), findsNothing);

    await tapDirectory(tester, '工作资料');
    expect(find.text('全选'), findsOneWidget);
    expect(find.byKey(const ValueKey('doc-check-doc-1')), findsOneWidget);

    // 勾选第一篇文档后点确定
    await tester.tap(find.byKey(const ValueKey('doc-check-doc-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(confirmed.length, 1);
    expect(confirmed.first, ['doc-1']);
  });

  testWidgets('公共文档模式：一次请求 getPublicDocList，按 directoryName 分组，展开不再请求，无操作图标', (tester) async {
    await tester.pumpWidget(buildWidget(publicMode: true));
    await tester.pumpAndSettle();

    // 只调用一次公开文档接口（带 tenantId 与 companyId），不请求目录列表
    expect(requestLog.length, 1);
    expect(requestLog.first, contains('GET /service/chat/getPublicDocList'));
    expect(requestLog.first, contains('tenantId=t1'));
    expect(requestLog.first, contains('companyId=c1'));
    expect(find.text('工作资料'), findsNothing);

    // 按 directoryName 分组显示目录卡片，未展开不显示文档
    expect(find.text('公司共享'), findsOneWidget);
    expect(find.text('培训资料'), findsOneWidget);
    expect(find.text('公开制度.pdf'), findsNothing);

    // 展开分组：直接显示该分组的文档，不再请求接口，箭头转90度
    await tapDirectory(tester, '公司共享');
    expect(find.text('公开制度.pdf'), findsOneWidget);
    expect(requestLog.length, 1);
    expect(arrowAngle(tester, '公司共享'), closeTo(0, 0.0001));

    // 收起后再展开同样不请求接口
    await tapDirectory(tester, '公司共享');
    expect(find.text('公开制度.pdf'), findsNothing);
    expect(arrowAngle(tester, '公司共享'), closeTo(1, 0.0001));
    await tapDirectory(tester, '公司共享');
    expect(find.text('公开制度.pdf'), findsOneWidget);
    expect(requestLog.length, 1);

    // 另一个分组也能展开，同样不请求
    await tapDirectory(tester, '培训资料');
    expect(find.text('培训资料.txt'), findsOneWidget);
    expect(requestLog.length, 1);

    // 公共文档可能属于他人：不显示"三个点"（修改权限/删除）入口，复选框与全选仍在
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('全选'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('doc-check-pub-1')), findsOneWidget);
  });
}
