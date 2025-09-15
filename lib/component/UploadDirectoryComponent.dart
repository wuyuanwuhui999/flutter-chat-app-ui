import 'package:flutter/material.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:flutter_music_app/theme/ThemeColors.dart';
import 'package:flutter_music_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';
import '../common/constant.dart';
import '../model/DirectoryModel.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeSize.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/HttpUtil.dart';

// 有状态的目录列表组件（内部管理选中状态）
class UploadDirectoryComponent extends StatefulWidget {
  const UploadDirectoryComponent({
    super.key,
  });

  @override
  State<UploadDirectoryComponent> createState() =>
      _UploadDirectoryComponentState();
}

class _UploadDirectoryComponentState extends State<UploadDirectoryComponent> {
  List<DirectoryModel> directoryList = [
    DirectoryModel(
        id: "default", userId: "", directory: "默认文件夹", isSelected: false)
  ];
  String directoryId = "";
  late ChatProvider chatProvider;

  @override
  void initState() {
    getDirectoryList();
    super.initState();
  }

  getDirectoryList() {
    chatProvider = Provider.of<ChatProvider>(context,listen: false);
    getDirectoryListService(chatProvider.tenantUser.tenantId)
        .then((res) {
      res.data.forEach((item) {
        directoryList.add(DirectoryModel.fromJson(item));
      });
      chatProvider.setDirectoryList(directoryList);
    });
  }

  ///@author: wuwenqiang
  ///@description: 文档上传
  /// @date: 2025-09-13 13:17
  Future<void> onUploadDoc() async {
    if (directoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个文件夹')),
      );
      return;
    }

    // 选择文件 - 只允许PDF和TXT格式
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return; // 用户取消了选择
    }

    // 检查文件格式
    final fileName = result.files.single.name.toLowerCase();
    if (!fileName.endsWith('.pdf') && !fileName.endsWith('.txt')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只支持上传PDF和TXT格式的文档')),
      );
      return;
    }

    // 关闭弹窗
    Navigator.of(context).pop();

    // 显示loading图标
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('文件上传中...'),
            ],
          ),
        );
      },
    );

    try {
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      // 获取token和tenantId
      final tenantId = chatProvider.tenantUser.tenantId;

      // 使用HttpUtil上传文件
      final httpUtil = HttpUtil.getInstance();
      final response = await httpUtil.uploadDoc(
        filePath: filePath,
        fileName: fileName,
        tenantId: tenantId,
        directoryId: directoryId,
      );

      // 关闭loading对话框
      Navigator.of(context).pop();

      if (response.status == SUCCESS) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件上传成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${response.msg}')),
        );
      }
    } catch (e) {
      // 关闭loading对话框
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: $e')),
      );
    }
  }

  List<Widget> getDirectoryListWidget(){
    List<Widget>directoryListWidget = [];
    chatProvider.directoryList.asMap().forEach((index,item){
      directoryListWidget.add(Container(
          padding: EdgeInsets.only(
              top: index == 0 ? 0 : ThemeSize.containerPadding,
              bottom: index ==
                  chatProvider.directoryList.length - 1
                  ? 0
                  : ThemeSize.containerPadding),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      width: 1,
                      color: index ==
                          chatProvider.directoryList.length -
                              1
                          ? Colors.transparent
                          : ThemeColors.disableColor,
                      style: BorderStyle.solid))),
          child: Row(children: [
            Expanded(child: Text(item.directory)),
            // 右边单选按钮
            GestureDetector(
              onTap: () => selectItem(index),
              child: Container(
                width: ThemeSize.radioSize,
                height: ThemeSize.radioSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isSelected
                        ? Colors.blue
                        : Colors.grey,
                    width: 2,
                  ),
                  color: item.isSelected
                      ? Colors.blue
                      : Colors.transparent,
                ),
                child: item.isSelected
                    ? const Icon(
                  Icons.check,
                  size: ThemeSize.middleFontSize,
                  color: Colors.white,
                )
                    : null,
              ),
            )
          ])));
    });
    return directoryListWidget;
  }


  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context, listen: true);
    return Column(
      children: [
        Expanded(
            child: Container(
          decoration: const BoxDecoration(color: ThemeColors.colorBg),
          child: SingleChildScrollView(
              child: Container(
                  width: double.infinity,
                  decoration: ThemeStyle.boxDecoration,
                  padding: ThemeStyle.padding,
                  margin: ThemeStyle.padding,
                  child: Column(
                      children:getDirectoryListWidget()
                  ))),
        )),
        Container(
            decoration: const BoxDecoration(color: Colors.transparent),
            padding: ThemeStyle.padding,
            child: Row(children: [
              Expanded(
                  flex: 1,
                  child: OutlinedButton(
                      onPressed: onUploadDoc,

                      ///圆角
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.transparent),
                        backgroundColor: ThemeColors.activeColor,
                        foregroundColor: ThemeColors.activeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(ThemeSize.bigRadius), // 圆角
                        ),
                      ),
                      child: const Text(
                        '确定',
                        style: TextStyle(
                            fontSize: ThemeSize.middleFontSize,
                            color: ThemeColors.colorWhite),
                      ))),
              const SizedBox(width: ThemeSize.containerPadding),
              Expanded(
                  flex: 1,
                  child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },

                      ///圆角
                      style: OutlinedButton.styleFrom(
                        backgroundColor: ThemeColors.colorWhite,
                        foregroundColor: ThemeColors.colorWhite,
                        side: const BorderSide(color: ThemeColors.subTitle),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(ThemeSize.bigRadius), // 圆角
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                            fontSize: ThemeSize.middleFontSize,
                            color: ThemeColors.subTitle),
                      )))
            ]))
      ],
    );
  }

  // 选择项目的方法
  void selectItem(int index) {
    setState(() {
      // 取消所有选择
      for (var directory in directoryList) {
        directory.isSelected = false;
      }
      // 选择当前项目
      directoryList[index].isSelected = true;
      directoryId = directoryList[index].id;
    });
  }
}
