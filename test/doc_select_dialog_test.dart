import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_chat_app/component/DocSelectDialog.dart';
import 'package:flutter_chat_app/model/CompanyModel.dart';
import 'package:flutter_chat_app/model/TenantModel.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/utils/HttpUtil.dart';

/// 通过替换 dio 的 HttpClientAdapter 模拟后端，验证"选择文档"弹窗：
/// 1、标题栏为居中的"我的文档 ｜ 公共文档"页签，默认激活"我的文档"（主色），未激活为黑色正文色；
/// 2、默认走我的文档逻辑（只请求目录列表）；点击"公共文档"页签才调用 getPublicDocList；
/// 3、公共文档按 directoryName 分组显示目录卡片，展开直接显示文档、不再请求接口；
/// 4、两个页签的勾选合并，确定时一起返回
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.requestLog);

  /// 请求记录：'METHOD path?query body'
  final List<String> requestLog;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestLog.add('${options.method} ${options.uri.path}?${options.uri.query}');
    return ResponseBody.fromString(
      _route(options.uri.path),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  String _route(String path) {
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
            'permission': 'company',
          },
        ],
      });
    }
    if (path == '/service/chat/getPublicDocList') {
      // 公开文档接口一次性返回全部文档，且带 directoryName（文档目录名称）
      // 其中 pub-3 的 directoryName 为 null，应归入"默认文件夹"分组（与 pub-2 同一组）
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
            'directoryId': 'default',
            'directoryName': '默认文件夹',
            'name': '培训资料.txt',
            'ext': 'txt',
            'userId': 'other-user',
            'permission': 'tenant',
          },
          {
            'id': 'pub-3',
            'tenantId': 't1',
            'companyId': 'c1',
            'directoryId': 'dir-9',
            'directoryName': null,
            'name': '无目录文档.txt',
            'ext': 'txt',
            'userId': 'other-user',
            'permission': 'tenant',
          },
        ],
      });
    }
    return jsonEncode({'status': 'FAIL', 'msg': '未知接口', 'data': null});
  }

  @override
  void close({bool force = false}) {}
}

/// 宿主：点按钮打开"选择文档"弹窗，并把弹窗返回值抛给测试用例
class _DialogHost extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>?> onResult;
  final Function(List<String>, List<String>)? onSelectionChanged;

  const _DialogHost({required this.onResult, this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext ctx) => Center(
          child: ElevatedButton(
            key: const ValueKey('open-doc-select'),
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: ctx,
                barrierDismissible: false,
                builder: (_) => DocSelectDialog(
                  onSelectionChanged: onSelectionChanged,
                ),
              );
              onResult(result);
            },
            child: const Text('打开选择文档'),
          ),
        ),
      ),
    );
  }
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
    ValueChanged<Map<String, dynamic>?>? onResult,
    Function(List<String>, List<String>)? onSelectionChanged,
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
        home: _DialogHost(
          onResult: onResult ?? (_) {},
          onSelectionChanged: onSelectionChanged,
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('open-doc-select')));
    await tester.pumpAndSettle();
  }

  TextStyle? tabStyle(WidgetTester tester, String text) {
    return tester.widget<Text>(find.text(text)).style;
  }

  testWidgets('需求1+2：标题栏为居中的"我的文档 ｜ 公共文档"页签，默认激活我的文档', (tester) async {
    await tester.pumpWidget(buildWidget());
    await openDialog(tester);

    // 两个页签 + 分隔符
    expect(find.text('我的文档'), findsOneWidget);
    expect(find.text('公共文档'), findsOneWidget);
    expect(find.text('｜'), findsOneWidget);

    // 标题栏页签整行居中对齐（DialogComponent 的标题栏用 Center 包裹）
    final Row tabBar =
        tester.widget<Row>(find.byKey(const ValueKey('doc-select-tab-bar')));
    expect(tabBar.mainAxisAlignment, MainAxisAlignment.center);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('doc-select-tab-bar')),
        matching: find.byType(Center),
      ),
      findsWidgets,
    );

    // 默认激活"我的文档"（主色+加粗），"公共文档"为黑色正文色（未激活）
    expect(tabStyle(tester, '我的文档')!.color, ThemeColors.primary);
    expect(tabStyle(tester, '我的文档')!.fontWeight, FontWeight.bold);
    expect(tabStyle(tester, '公共文档')!.color, ThemeColors.mainTitle);
    expect(tabStyle(tester, '公共文档')!.fontWeight, FontWeight.normal);

    // 默认显示我的文档：只请求目录列表，且没有请求公开文档接口
    expect(requestLog.length, 1);
    expect(requestLog.single,
        contains('GET /service/chat/getDirectoryList?tenantId=t1'));
    expect(find.text('工作资料'), findsOneWidget);
    expect(find.text('学习资料'), findsOneWidget);
    // 我的文档页签未展开目录时不显示文档
    expect(find.text('需求文档.pdf'), findsNothing);
  });

  testWidgets('需求3+4：点击公共文档才请求接口，按 directoryName 分组，展开不再请求', (tester) async {
    await tester.pumpWidget(buildWidget());
    await openDialog(tester);

    // 切到公共文档页签
    await tester.tap(find.byKey(const ValueKey('doc-select-tab-1')));
    await tester.pumpAndSettle();

    // 激活状态互换
    expect(tabStyle(tester, '公共文档')!.color, ThemeColors.primary);
    expect(tabStyle(tester, '公共文档')!.fontWeight, FontWeight.bold);
    expect(tabStyle(tester, '我的文档')!.color, ThemeColors.mainTitle);

    // 调用 getPublicDocList，带上 tenantId 和 companyId
    expect(requestLog.length, 2);
    expect(
      requestLog[1],
      contains('GET /service/chat/getPublicDocList?tenantId=t1&companyId=c1'),
    );

    // 按 directoryName 分组显示目录卡片；directoryName 为空的归入"默认文件夹"（只应有一个该卡片）
    expect(find.text('公司共享'), findsOneWidget);
    expect(find.text('默认文件夹'), findsOneWidget);
    // 未展开不显示文档
    expect(find.text('公开制度.pdf'), findsNothing);
    expect(find.text('培训资料.txt'), findsNothing);

    // 展开"公司共享"：直接显示该分组文档，不产生新的请求
    await tester.tap(find.text('公司共享'));
    await tester.pumpAndSettle();
    expect(find.text('公开制度.pdf'), findsOneWidget);
    expect(requestLog.length, 2);

    // 展开"默认文件夹"：同一分组下的 null/默认目录文档都在这里，同样不产生请求
    await tester.tap(find.text('默认文件夹'));
    await tester.pumpAndSettle();
    expect(find.text('培训资料.txt'), findsOneWidget);
    expect(find.text('无目录文档.txt'), findsOneWidget);
    expect(requestLog.length, 2);

    // 公共文档可能属于他人：不显示"三个点"（修改权限/删除）入口
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });

  testWidgets('需求3：切回我的文档页签不重复请求，展开状态保留', (tester) async {
    await tester.pumpWidget(buildWidget());
    await openDialog(tester);

    // 我的文档展开目录（加载该目录文档）
    await tester.tap(find.text('工作资料'));
    await tester.pumpAndSettle();
    expect(find.text('需求文档.pdf'), findsOneWidget);
    expect(requestLog.length, 2);

    // 切到公共文档再切回来
    await tester.tap(find.byKey(const ValueKey('doc-select-tab-1')));
    await tester.pumpAndSettle();
    expect(requestLog.length, 3);
    await tester.tap(find.byKey(const ValueKey('doc-select-tab-0')));
    await tester.pumpAndSettle();

    // 页签保活：没有新增请求，且目录仍是展开状态（文档仍在显示）
    expect(requestLog.length, 3);
    expect(find.text('需求文档.pdf'), findsOneWidget);
    // 三个点入口在我的文档里仍然保留
    expect(find.byIcon(Icons.more_horiz), findsNWidgets(2));
  });

  testWidgets('需求5：两个页签的勾选合并，确定时一起返回', (tester) async {
    Map<String, dynamic>? result;
    final List<List<String>> selectionChanges = <List<String>>[];
    await tester.pumpWidget(buildWidget(
      onResult: (r) => result = r,
      onSelectionChanged: (ids, names) => selectionChanges.add(ids),
    ));
    await openDialog(tester);

    // 我的文档：勾选 doc-1
    await tester.tap(find.text('工作资料'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doc-check-doc-1')));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // 公共文档：勾选 pub-1
    await tester.tap(find.byKey(const ValueKey('doc-select-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('公司共享'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doc-check-pub-1')));
    await tester.pumpAndSettle();
    // 确定按钮上的数量为两个页签合并后的数量
    expect(find.text('2'), findsOneWidget);
    expect(selectionChanges.last, ['doc-1', 'pub-1']);

    // 确定 -> 返回两个页签合并后的文档ID和名称
    await tester.tap(find.byKey(const ValueKey('doc-select-confirm')));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!['docIds'], ['doc-1', 'pub-1']);
    expect(result!['docNames'], ['需求文档.pdf', '公开制度.pdf']);
  });

  testWidgets('需求5：取消返回 null，未勾选时确定按钮不可点击', (tester) async {
    Map<String, dynamic>? result;
    bool resultCalled = false;
    await tester.pumpWidget(buildWidget(onResult: (r) {
      resultCalled = true;
      result = r;
    }));
    await openDialog(tester);

    // 未勾选任何文档：确定按钮置灰不可点击
    final ElevatedButton confirm =
        tester.widget<ElevatedButton>(find.byKey(const ValueKey('doc-select-confirm')));
    expect(confirm.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('doc-select-cancel')));
    await tester.pumpAndSettle();
    expect(resultCalled, isTrue);
    expect(result, isNull);
  });
}
