import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/component/DocSettingDialog.dart';
import 'package:flutter_chat_app/model/DocSettingModel.dart';

void main() {
  testWidgets('文档设置对话框：默认值 + fixed 显示分割大小 + 返回值校验', (tester) async {
    final List<DocSettingModel?> results = <DocSettingModel?>[];

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final res = await DocSettingDialog.show(context: context);
                results.add(res);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    // 打开发送文档设置对话框
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 默认：权限=私密，分割模式=递归字符分割（推荐）
    expect(find.text('文档设置'), findsOneWidget);
    expect(find.text('私密'), findsOneWidget);
    expect(find.text('递归字符分割（推荐）'), findsOneWidget);
    // 非 fixed：分割大小输入框不可见
    expect(find.text('分割大小'), findsNothing);

    // 切换到"固定长度分割"
    await tester.tap(find.text('递归字符分割（推荐）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('固定长度分割'));
    await tester.pumpAndSettle();

    // fixed：分割大小输入框可见，默认值1000
    expect(find.text('固定长度分割'), findsOneWidget);
    expect(find.text('分割大小'), findsOneWidget);
    final TextField chunkField = tester.widget<TextField>(find.byType(TextField));
    expect(chunkField.controller!.text, '1000');

    // 修改分割大小为 500
    await tester.enterText(find.byType(TextField), '500');
    await tester.pumpAndSettle();

    // 点击确定
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(results.length, 1);
    final DocSettingModel? setting = results.first;
    expect(setting, isNotNull);
    expect(setting!.permission, DocSettingModel.permissionPrivate);
    expect(setting.splitMethod, DocSettingModel.splitMethodFixed);
    expect(setting.chunkSize, 500);
    // body 参数：fixed 时带 chunkSize
    expect(setting.toJson()['chunkSize'], 500);
    expect(setting.toJson()['permission'], 'private');
    expect(setting.toJson()['splitMethod'], 'fixed');
  });

  testWidgets('文档设置对话框：取消返回 null，切回其他分割模式时分割大小不生效', (tester) async {
    final List<DocSettingModel?> results = <DocSettingModel?>[];

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final res = await DocSettingDialog.show(context: context);
                results.add(res);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 权限切换为"公司内公开"
    await tester.tap(find.text('私密'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('公司内公开'));
    await tester.pumpAndSettle();
    expect(find.text('公司内公开'), findsOneWidget);

    // 先切到 fixed 再切回 paragraph，分割大小输入框应消失
    await tester.tap(find.text('递归字符分割（推荐）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('固定长度分割'));
    await tester.pumpAndSettle();
    expect(find.text('分割大小'), findsOneWidget);
    await tester.tap(find.text('固定长度分割'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按段落分割'));
    await tester.pumpAndSettle();
    expect(find.text('分割大小'), findsNothing);

    // 点击取消
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(results.length, 1);
    expect(results.first, isNull);

    // 非 fixed 时 body 中不下发 chunkSize
    final DocSettingModel setting = DocSettingModel(
      permission: DocSettingModel.permissionCompany,
      splitMethod: DocSettingModel.splitMethodParagraph,
    );
    expect(setting.toJson().containsKey('chunkSize'), isFalse);
    expect(setting.toJson()['permission'], 'company');
  });
}
