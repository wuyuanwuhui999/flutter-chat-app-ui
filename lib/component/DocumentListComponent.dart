import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';

import '../model/DirectoryModel.dart';
import '../model/DocModel.dart';
import '../model/DocumentCheckModel.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeSize.dart';
import 'TriangleComponent.dart';

/// @author: wuwenqiang
/// @description: 文档选择列表组件（支持多选，按目录分组）
/// @date: 2025-09-08
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
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 加载文档列表
  /// @date: 2025-09-08
  void _loadDocList() {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // ✅ 使用 currentTenantId
    final tenantId = chatProvider.currentTenantId;

    if (tenantId.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '请先选择租户';
        });
      }
      return;
    }

    getMyDocListService(tenantId).then((res) {
      if (!mounted) return;

      if (res.data.isNotEmpty) {
        final List<DocumentCheckModel> tempList = [];

        for (var doc in res.data) {
          final docModel = DocModel.fromJson(doc);
          final key = docModel.directoryId.isNotEmpty
              ? docModel.directoryId
              : 'default';

          // 查找是否存在该目录分组
          int index = tempList.indexWhere(
            (dItem) => dItem.directoryId == key,
          );

          if (index == -1) {
            // 不存在：创建新分组
            final newDocItem = DocumentCheckModel(
              expand: false,
              directoryId: key,
              directoryName: docModel.directoryName.isNotEmpty
                  ? docModel.directoryName
                  : '默认文件夹',
              docList: [],
            );
            newDocItem.docList.add(docModel);
            tempList.add(newDocItem);
          } else {
            // 存在：直接添加
            tempList[index].docList.add(docModel);
          }
        }

        setState(() {
          docList = tempList;
          isLoading = false;
        });
      } else {
        setState(() {
          docList = [];
          isLoading = false;
        });
      }
    }).catchError((error) {
      debugPrint('加载文档列表失败: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '加载失败，请重试';
        });
      }
    });
  }

  /// @author: wuwenqiang
  /// @description: 获取所有选中的文档ID
  /// @date: 2025-09-08
  void _getCheckedIds() {
    final List<String> checkedIds = [];
    for (var group in docList) {
      for (var doc in group.docList) {
        if (doc.checked) {
          checkedIds.add(doc.id);
        }
      }
    }
    widget.onItemSelected(checkedIds);
  }

  /// @author: wuwenqiang
  /// @description: 切换目录展开/收起
  /// @date: 2025-09-08
  void _toggleExpand(int index) {
    setState(() {
      docList[index].expand = !docList[index].expand;
    });
  }

  /// @author: wuwenqiang
  /// @description: 切换文档选中状态
  /// @date: 2025-09-08
  void _toggleDocCheck(int groupIndex, int docIndex) {
    setState(() {
      docList[groupIndex].docList[docIndex].checked =
          !docList[groupIndex].docList[docIndex].checked;
      _getCheckedIds();
    });
  }

  /// @author: wuwenqiang
  /// @description: 全选/取消全选某个目录下的所有文档
  /// @date: 2025-09-08
  void _toggleGroupAll(int groupIndex) {
    final group = docList[groupIndex];
    // 检查是否所有文档都已选中
    final allChecked = group.docList.every((doc) => doc.checked);
    final newChecked = !allChecked;

    setState(() {
      for (var doc in group.docList) {
        doc.checked = newChecked;
      }
      _getCheckedIds();
    });
  }

  /// @author: wuwenqiang
  /// @description: 刷新文档列表
  /// @date: 2025-09-08
  void _refreshDocs() {
    docList.clear();
    _loadDocList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(
                color: ThemeColors.gray,
                fontSize: ThemeSize.normalFont,
              ),
            ),
            const SizedBox(height: ThemeSize.middleGap),
            ElevatedButton(
              onPressed: _refreshDocs,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (docList.isEmpty) {
      return const Center(
        child: Text(
          '暂无文档',
          style: TextStyle(
            color: ThemeColors.gray,
            fontSize: ThemeSize.normalFont,
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(color: ThemeColors.background),
      child: SingleChildScrollView(
        child: Container(
          decoration: ThemeStyle.boxDecoration,
          padding: ThemeStyle.padding,
          margin: ThemeStyle.padding,
          child: Column(
            children: docList.asMap().entries.map((entry) {
              final groupIndex = entry.key;
              final group = entry.value;
              final isLastGroup = groupIndex == docList.length - 1;

              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: groupIndex == 0 ? 0 : ThemeSize.middleGap,
                  bottom: isLastGroup ? 0 : ThemeSize.middleGap,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: isLastGroup
                          ? Colors.transparent
                          : ThemeColors.gray,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 目录标题（可点击展开/收起）
                    GestureDetector(
                      onTap: () => _toggleExpand(groupIndex),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.directoryName,
                              style: const TextStyle(
                                fontSize: ThemeSize.normalFont,
                                fontWeight: FontWeight.w500,
                                color: ThemeColors.mainTitle,
                              ),
                            ),
                          ),
                          // 全选/取消全选按钮
                          GestureDetector(
                            onTap: () => _toggleGroupAll(groupIndex),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ThemeSize.smallMargin,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeColors.primary,
                                borderRadius: BorderRadius.circular(
                                  ThemeSize.minBtnRadius,
                                ),
                              ),
                              child: Text(
                                group.docList.every((doc) => doc.checked)
                                    ? '取消全选'
                                    : '全选',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: ThemeSize.smallFont,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: ThemeSize.smallMargin),
                          // 展开/收起箭头
                          Transform.rotate(
                            angle: group.expand ? 0 : -pi / 2,
                            child: Opacity(
                              opacity: 0.3,
                              child: Image.asset(
                                "lib/assets/images/icon_down.png",
                                width: ThemeSize.miniIcon,
                                height: ThemeSize.miniIcon,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 文档列表（展开时显示）
                    if (group.expand)
                      Column(
                        children: group.docList.asMap().entries.map((docEntry) {
                          final docIndex = docEntry.key;
                          final doc = docEntry.value;

                          return Padding(
                            padding: const EdgeInsets.only(
                              top: ThemeSize.smallMargin,
                              left: ThemeSize.smallMargin,
                            ),
                            child: Row(
                              children: [
                                // 文档图标
                                Image.asset(
                                  _getDocIcon(doc.ext),
                                  width: ThemeSize.smallIcon,
                                  height: ThemeSize.smallIcon,
                                ),
                                const SizedBox(width: ThemeSize.smallMargin),
                                Expanded(
                                  child: Text(
                                    doc.name,
                                    style: const TextStyle(
                                      color: ThemeColors.mainTitle,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: ThemeSize.smallMargin),
                                // 单选按钮
                                GestureDetector(
                                  onTap: () => _toggleDocCheck(groupIndex, docIndex),
                                  child: Container(
                                    width: ThemeSize.radioSize,
                                    height: ThemeSize.radioSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: doc.checked
                                            ? ThemeColors.primary
                                            : ThemeColors.gray,
                                        width: 2,
                                      ),
                                      color: doc.checked
                                          ? ThemeColors.primary
                                          : Colors.transparent,
                                    ),
                                    child: doc.checked
                                        ? const Icon(
                                            Icons.check,
                                            size: ThemeSize.middleFont,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 根据文件扩展名获取对应的图标
  /// @date: 2025-09-08
  String _getDocIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'lib/assets/images/icon_pdf.png';
      case 'txt':
        return 'lib/assets/images/icon_txt.png';
      case 'doc':
      case 'docx':
        return 'lib/assets/images/icon_doc.png';
      case 'xls':
      case 'xlsx':
        return 'lib/assets/images/icon_excel.png';
      case 'ppt':
      case 'pptx':
        return 'lib/assets/images/icon_ppt.png';
      default:
        return 'lib/assets/images/icon_file.png';
    }
  }
}