import 'package:flutter/material.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/service/serverMethod.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';
import '../model/DocModel.dart';
import '../theme/ThemeSize.dart';
import '../utils/common.dart';

/// @author: wuwenqiang
/// @description: 文档列表组件（按目录分组显示）
/// @date: 2025-09-08
class DocListComponent extends StatefulWidget {
  const DocListComponent({
    super.key,
  });

  @override
  State<DocListComponent> createState() => _DocListComponentState();
}

class _DocListComponentState extends State<DocListComponent> {
  List<List<DocModel>> docList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // 在 initState 中不直接调用 Provider，使用 WidgetsBinding 延迟执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocs();
    });
  }

  /// @author: wuwenqiang
  /// @description: 加载文档列表
  /// @date: 2025-09-08
  Future<void> _loadDocs() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 使用 listen: false 来获取 provider，不监听变化
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

      final res = await getMyDocListService(tenantId);

      if (!mounted) return;

      if (res.data.isNotEmpty) {
        // 使用 Map 来按 directoryId 分组
        final Map<String, List<DocModel>> groupedMap = {};
        for (var doc in res.data) {
          final docModel = DocModel.fromJson(doc);
          final key = docModel.directoryId.isNotEmpty
              ? docModel.directoryId
              : 'default';

          if (!groupedMap.containsKey(key)) {
            groupedMap[key] = [];
          }
          groupedMap[key]!.add(docModel);
        }

        setState(() {
          // 将 Map 的值转换为二维列表
          docList = groupedMap.values.toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          docList = [];
        });
      }
    } catch (e) {
      debugPrint('加载文档列表失败: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '加载失败，请重试';
        });
      }
    }
  }

  /// @author: wuwenqiang
  /// @description: 刷新文档列表
  /// @date: 2025-09-08
  Future<void> _refreshDocs() async {
    await _loadDocs();
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: docList.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: ThemeColors.gray,
      ),
      itemBuilder: (context, index) {
        final docItems = docList[index];
        if (docItems.isEmpty) return const SizedBox();

        return Padding(
          padding: ThemeStyle.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 目录标题
              Text(
                docItems[0].directoryName.isNotEmpty
                    ? docItems[0].directoryName
                    : '默认文件夹',
                style: const TextStyle(
                  fontSize: ThemeSize.normalFont,
                  fontWeight: FontWeight.w500,
                  color: ThemeColors.mainTitle,
                ),
              ),
              const SizedBox(height: ThemeSize.smallMargin),
              // 目录下的文档列表
              ...docItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: ThemeSize.smallMargin,
                    left: ThemeSize.smallMargin,
                  ),
                  child: Row(
                    children: [
                      // 文档图标
                      Image.asset(
                        _getDocIcon(item.ext),
                        width: ThemeSize.smallIcon,
                        height: ThemeSize.smallIcon,
                      ),
                      const SizedBox(width: ThemeSize.smallMargin),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: item.name,
                                style: const TextStyle(
                                  color: ThemeColors.mainTitle,
                                ),
                              ),
                              TextSpan(
                                text: "  ${formatTimeAgo(item.createTime)}",
                                style: const TextStyle(
                                  color: ThemeColors.gray,
                                  fontSize: ThemeSize.smallFont,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
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