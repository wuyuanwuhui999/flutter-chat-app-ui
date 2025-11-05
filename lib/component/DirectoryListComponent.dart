import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:flutter_music_app/theme/ThemeColors.dart';
import 'package:flutter_music_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';

import '../model/DirectoryModel.dart';
import '../model/DocModel.dart';
import '../model/DocumentCheckModel.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeSize.dart';
import 'TriangleComponent.dart';

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
  List<DocumentCheckModel> docList = [];

  @override
  void initState() {
    getDocList();
    super.initState();
  }

  getDocList() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.tenantUser?.tenantId;
    getMyDocListService(tenantId).then((res) {
      setState(() {
        for (var doc in res.data) {
          DocModel docModel = DocModel.fromJson(doc);
          // 安全查找：找不到返回 null
          int index = docList
              .indexWhere((dItem) => dItem.directoryId == docModel.directoryId);
          if (index == -1) {
            // 不存在：创建新分组
            DocumentCheckModel newDocItem = DocumentCheckModel(
              expand: false,
              directoryId: docModel.directoryId,
              directoryName: docModel.directoryName, // 确保 DocModel 有这个字段
              docList: [],
            );
            docList.add(newDocItem);
            newDocItem.docList.add(docModel);
          } else {
            // 存在：直接添加
            docList[index].docList.add(docModel);
          }
        }
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
                  children: docList.asMap().entries.map((item) {
                return Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                        top: item.key == 0 ? 0 : ThemeSize.containerPadding,
                        bottom: item.key == docList.length - 1
                            ? 0
                            : ThemeSize.containerPadding),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: 1,
                                color: item.key == docList.length - 1
                                    ? Colors.transparent
                                    : ThemeColors.disableColor,
                                style: BorderStyle.solid))),
                    child: Column(
                      children: [
                        Row(children: [
                          Text(item.value.directoryName),
                          // 右边单选按钮
                          const SizedBox(width: ThemeSize.smallMargin),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                item.value.expand = !item.value.expand;
                              });
                            },
                            child: Transform.rotate(
                              angle: item.value.expand ? 0 : -pi / 2,
                              // 旋转-90度（π/2弧度）
                              child: Opacity(
                                  child: Image.asset(
                                    "lib/assets/images/icon_down.png",
                                    width: ThemeSize.miniIcon,
                                    height: ThemeSize.miniIcon,
                                  ),
                                  opacity: 0.3),
                            ),
                            // child: Image.asset("lib/assets/images/icon_down.png",width: ThemeSize.smallIcon,height: ThemeSize.smallIcon),
                          )
                        ]),
                        item.value.expand
                            ? Column(
                                children: item.value.docList.map((cItem) {
                                  return Row(
                                      children: [
                                        Text(cItem.directoryName),
                                        GestureDetector(
                                          onTap: (){
                                            cItem.checked = !cItem.checked;
                                          },
                                          child: Container(
                                            width: ThemeSize.radioSize,
                                            height: ThemeSize.radioSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: cItem.checked
                                                    ? Colors.blue
                                                    : Colors.grey,
                                                width: 2,
                                              ),
                                              color: cItem.checked
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                            ),
                                            child: cItem.checked
                                                ? const Icon(
                                              Icons.check,
                                              size: ThemeSize.middleFontSize,
                                              color: Colors.white,
                                            )
                                                : null,
                                          ),
                                        )
                                      ]);
                                }).toList(),
                              )
                            : const SizedBox()
                      ],
                    ));
              }).toList()))),
    );
  }
}
