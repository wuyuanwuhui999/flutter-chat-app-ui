import 'package:flutter/material.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:flutter_music_app/service/serverMethod.dart';
import 'package:flutter_music_app/theme/ThemeColors.dart';
import 'package:flutter_music_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';
import '../model/DocModel.dart';
import '../theme/ThemeSize.dart';
import '../utils/common.dart';

// 有状态的目录列表组件（内部管理选中状态）
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

  @override
  void initState() {
    super.initState();
    // 在 initState 中不直接调用 Provider，使用 WidgetsBinding 延迟执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocs();
    });
  }

  // 在 didChangeDependencies 中获取 provider 数据
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 也可以在这里加载数据
  }

  Future<void> _loadDocs() async {
    try {
      // 使用 listen: false 来获取 provider，不监听变化
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final tenantId = chatProvider.tenantUser?.tenantId;

      if (tenantId == null) {
        print('tenantId is null');
        return;
      }

      var res = await getMyDocListService(tenantId);

      if (res.data.isNotEmpty) {
        // 使用 Map 来按 directoryId 分组
        Map<String, List<DocModel>> groupedMap = {};
        for (var doc in res.data) {
          // 如果该 directoryId 还没有对应的列表，就创建一个
          DocModel docModel = DocModel.fromJson(doc);
          if (!groupedMap.containsKey(docModel.directoryId)) {
            groupedMap[docModel.directoryId] = [];
          }
          // 将文档添加到对应的分组中
          groupedMap[docModel.directoryId]!.add(docModel);
        }

        if (mounted) {
          setState(() {
            // 将 Map 的值转换为二维列表
            docList = groupedMap.values.toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载文档列表失败: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (docList.isEmpty) {
      return const Center(
        child: Text('暂无文档', style: TextStyle(color: ThemeColors.disableColor)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: docList.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey,
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
                  docItems[0].directoryName,
                ),

                // 目录下的文档列表
                ...docItems.map((item) {
                  return Padding(
                      padding: const EdgeInsets.only(top: ThemeSize.smallMargin),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: item.name),
                            TextSpan(
                              text: "  ${formatTimeAgo(item.createTime)}",
                              style: const TextStyle(
                                color: ThemeColors.disableColor,
                              ),
                            ),
                          ],
                        ),
                      ));
                }),
              ],
            ));
      },
    );
  }
}
