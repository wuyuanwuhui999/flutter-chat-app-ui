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
class DocumentListComponent extends StatefulWidget {
  final Function(List<String> docIds) onItemSelected;

  const DocumentListComponent({
    super.key,
    required this.onItemSelected,
  });

  @override
  State<DocumentListComponent> createState() => _DocumentListComponentState();
}

class _DocumentListComponentState extends State<DocumentListComponent> {
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

  getChecked(){
    List<String>checkedIds = [];
    docList.forEach((aItem){
      aItem.docList.forEach((bItem){
        if(bItem.checked){
          checkedIds.add(bItem.id);
        }
      });
    });
    widget.onItemSelected(checkedIds);
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
                        GestureDetector(onTap: (){
                          setState(() {
                            item.value.expand = !item.value.expand;
                          });
                        },child: Row(children: [
                          Text(item.value.directoryName),
                          // 右边单选按钮
                          const SizedBox(width: ThemeSize.smallMargin),
                          Transform.rotate(
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
                          Expanded(child: SizedBox(),flex: 1,)
                        ])),
                        item.value.expand
                            ? Column(
                                children: item.value.docList.map((cItem) {
                                  return Padding(padding: EdgeInsets.only(top: ThemeSize.smallMargin),
                                  child: Row(
                                      children: [
                                        Expanded(child: Text(cItem.name),flex: 1),
                                        SizedBox(width: ThemeSize.smallMargin),
                                        GestureDetector(
                                          onTap: (){
                                            setState(() {
                                              cItem.checked = !cItem.checked;
                                              getChecked();
                                            });
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
                                      ]),)
                                   ;
                                }).toList(),
                              )

                            : const SizedBox()
                      ],
                    ));
              }).toList()))),
    );
  }
}
