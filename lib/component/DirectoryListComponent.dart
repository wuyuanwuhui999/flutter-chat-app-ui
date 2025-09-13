import 'package:flutter/material.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:flutter_music_app/theme/ThemeColors.dart';
import 'package:flutter_music_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';
import '../model/DirectoryModel.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeSize.dart';

// 有状态的目录列表组件（内部管理选中状态）
class DirectoryListComponent extends StatefulWidget {
  final Function(String directoryId)? onItemSelected;

  const DirectoryListComponent({
    super.key,
    this.onItemSelected,
  });

  @override
  State<DirectoryListComponent> createState() => _DirectoryListComponentState();
}

class _DirectoryListComponentState extends State<DirectoryListComponent> {
  List<DirectoryModel> directoryList = [
    DirectoryModel(
        id: "default", userId: "", directory: "默认文件夹", isSelected: false)
  ];

  @override
  void initState() {
    getDirectoryList();
    super.initState();
  }

  getDirectoryList() {
    getDirectoryListService(Provider.of<ChatProvider>(context, listen: false)
            .tenantUser
            .tenantId)
        .then((res) {
      setState(() {
        res.data.forEach((item) {
          directoryList.add(DirectoryModel.fromJson(item));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: ThemeColors.colorBg),
      child: SingleChildScrollView(
          child: Container(
              decoration: ThemeStyle.boxDecoration,
              padding: ThemeStyle.padding,
              margin: ThemeStyle.padding,
              child: Column(
                  children: directoryList.asMap().entries.map((item) {
                return Container(
                  padding: EdgeInsets.only(
                    top: item.key == 0 ? 0 : ThemeSize.containerPadding,
                    bottom: item.key == directoryList.length - 1 ? 0 : ThemeSize.containerPadding
                  ),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: 1,
                                color: item.key == directoryList.length - 1 ? Colors.transparent :ThemeColors.disableColor,
                                style: BorderStyle.solid))),
                    child: Row(children: [
                      Expanded(child: Text(item.value.directory)),
                      // 右边单选按钮
                      GestureDetector(
                        onTap: () => selectItem(item.key),
                        child: Container(
                          width: ThemeSize.radioSize,
                          height: ThemeSize.radioSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.value.isSelected
                                  ? Colors.blue
                                  : Colors.grey,
                              width: 2,
                            ),
                            color: item.value.isSelected
                                ? Colors.blue
                                : Colors.transparent,
                          ),
                          child: item.value.isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: ThemeSize.middleFontSize,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      )
                    ]));
              }).toList()))),
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
      if (widget.onItemSelected != null)
        widget.onItemSelected!(directoryList[index].id);
    });
  }
}
