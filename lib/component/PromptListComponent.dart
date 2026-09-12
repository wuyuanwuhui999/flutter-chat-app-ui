import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../common/constant.dart';
import '../model/PromptModel.dart';
import '../provider/ChatProvider.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../router/index.dart';

/// @author: wuwenqiang
/// @description: 提示词列表组件（支持搜索、分页、左滑操作）
/// @date: 2026-09-11
class PromptListComponent extends StatefulWidget {
  final Function(String? promptId, String? promptContent) onSelectionChanged;
  final Function(String? promptId, String? promptContent) onConfirm;
  final VoidCallback onCancel;

  const PromptListComponent({
    super.key,
    required this.onSelectionChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<PromptListComponent> createState() => _PromptListComponentState();
}

class _PromptListComponentState extends State<PromptListComponent> {
  List<PromptModel> _promptList = [];
  bool _isLoading = true;
  String? _errorMessage;
  EasyRefreshController _controller = EasyRefreshController();
  TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  int _pageNum = 1;
  int _total = 0;
  String _keyword = '';

  // 弹窗内临时选中的提示词ID（点击确定后才生效）
  String? _tempPromptId;
  String? _tempPromptContent;

  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // 初始化时，从 ChatProvider 读取当前已选中的提示词
      _tempPromptId = _chatProvider.promptId;
      _loadPromptList(reset: true);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// @author: wuwenqiang
  /// @description: 搜索框内容变化（带防抖）
  /// @date: 2026-09-11
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _keyword = _searchController.text.trim();
      _loadPromptList(reset: true);
    });
  }

  /// @author: wuwenqiang
  /// @description: 加载提示词列表
  /// @date: 2026-09-11
  void _loadPromptList({bool reset = false}) {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _pageNum = 1;
      });
    }

    final tenantId = _chatProvider.currentTenantId;
    if (tenantId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先选择租户';
      });
      return;
    }

    getPromptListService(tenantId, _keyword, _pageNum, PAGE_SIZE)
        .then((res) {
      if (!mounted) return;
      setState(() {
        _total = res.total ?? 0;
        final newList =
        res.data.map((item) => PromptModel.fromJson(item)).toList();
        if (reset) {
          _promptList = newList;
        } else {
          _promptList.addAll(newList);
        }
        _isLoading = false;
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载提示词失败，请重试';
      });
    });
  }

  /// @author: wuwenqiang
  /// @description: 刷新提示词列表
  /// @date: 2026-09-11
  void _onRefresh() {
    _loadPromptList(reset: true);
  }

  /// @author: wuwenqiang
  /// @description: 跳转到添加提示词页面
  /// @date: 2026-09-11
  void _onAddPrompt() {
    Routes.router.navigateTo(context, '/AddPromptPage', replace: false);
  }

  /// @author: wuwenqiang
  /// @description: 删除提示词
  /// @date: 2026-09-11
  void _onDeletePrompt(int index) {
    final prompt = _promptList[index];
    final tenantId = _chatProvider.currentTenantId;

    showCupertinoDialog(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除提示词 "${prompt.prompt}" 吗？'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消',
                  style: TextStyle(color: ThemeColors.subTitle)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _doDeletePrompt(index, prompt.id, tenantId);
              },
              child:
              const Text('删除', style: TextStyle(color: ThemeColors.warn)),
            ),
          ],
        );
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 执行删除提示词
  /// @date: 2026-09-11
  void _doDeletePrompt(int index, String promptId, String tenantId) {
    deletePromptService(promptId, tenantId).then((res) {
      if (!mounted) return;
      if (res.data > 0) {
        setState(() {
          _promptList.removeAt(index);
          // 如果删除的是当前选中的提示词，清空选中状态
          if (_tempPromptId == promptId) {
            _tempPromptId = null;
            _tempPromptContent = null;
          }
        });
        Fluttertoast.showToast(
          msg: "删除成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      } else {
        Fluttertoast.showToast(
          msg: res.msg ?? "删除失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      }
    }).catchError((error) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "删除失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 使用/取消使用提示词
  /// @date: 2026-09-11
  void _onToggleUse(int index) {
    final prompt = _promptList[index];
    setState(() {
      if (_tempPromptId == prompt.id) {
        // 取消使用
        _tempPromptId = null;
        _tempPromptContent = null;
      } else {
        // 使用
        _tempPromptId = prompt.id;
        _tempPromptContent = prompt.prompt;
      }
    });
    widget.onSelectionChanged(_tempPromptId, _tempPromptContent);
  }

  /// @author: wuwenqiang
  /// @description: 编辑提示词（跳转到添加页面，可复用）
  /// @date: 2026-09-11
  void _onEditPrompt(int index) {
    // 编辑功能暂不复用 AddPromptPage，后续可扩展
    Fluttertoast.showToast(
      msg: "编辑功能开发中",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }

  /// @author: wuwenqiang
  /// @description: 确认选择
  /// @date: 2026-09-11
  void _onConfirm() {
    if (_tempPromptId == null) {
      Fluttertoast.showToast(
        msg: "请先选择一条提示词",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }
    widget.onConfirm(_tempPromptId, _tempPromptContent);
  }

  /// @author: wuwenqiang
  /// @description: 取消
  /// @date: 2026-09-11
  void _onCancel() {
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(color: ThemeColors.background),
        // padding:const EdgeInsets.all(ThemeSize.middleGap),
        child:Column(
      children: [
        // 搜索框
        _buildSearchBar(),
        // 列表内容
        Expanded(
          child: Container(
            color: ThemeColors.background,
            child: _buildContent(),
          ),
        ),
        // 底部按钮
        _buildBottomButtons(),
      ],
    ));
  }

  /// @author: wuwenqiang
  /// @description: 搜索框
  /// @date: 2026-09-11
  Widget _buildSearchBar() {
    return
      Container(
        margin: const EdgeInsets.all(ThemeSize.middleGap),
        height: ThemeSize.inputHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ThemeSize.inputHeight / 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: ThemeSize.middleGap),
            Image.asset(
              "lib/assets/images/icon_search.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
            const SizedBox(width: ThemeSize.smallMargin),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _searchController,
                cursorColor: ThemeColors.gray,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: "请输入关键词搜索",
                  hintStyle: TextStyle(
                    fontSize: ThemeSize.smallFont,
                    color: ThemeColors.gray,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _keyword = '';
                  _loadPromptList(reset: true);
                },
                child: Image.asset(
                  "lib/assets/images/icon_clear.png",
                  width: ThemeSize.smallIcon,
                  height: ThemeSize.smallIcon,
                ),
              ),
            if (_searchController.text.isNotEmpty)
              const SizedBox(width: ThemeSize.smallMargin),
            const SizedBox(width: ThemeSize.middleGap),
          ],
        ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 列表内容
  /// @date: 2026-09-11
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: ThemeColors.gray,
                fontSize: ThemeSize.normalFont,
              ),
            ),
            const SizedBox(height: ThemeSize.middleGap),
            ElevatedButton(
              onPressed: _onRefresh,
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
    if (_promptList.isEmpty) {
      return const Center(
        child: Text(
          '暂无提示词',
          style: TextStyle(
            color: ThemeColors.gray,
            fontSize: ThemeSize.normalFont,
          ),
        ),
      );
    }

    return EasyRefresh(
      controller: _controller,
      footer: ClassicalFooter(
        loadText: '上拉加载',
        loadReadyText: '准备加载',
        loadingText: '加载中...',
        loadedText: '加载完成',
        noMoreText: '没有更多',
        bgColor: Colors.transparent,
        textColor: ThemeColors.gray,
      ),
      onLoad: () async {
        if (_pageNum * PAGE_SIZE < _total) {
          _pageNum++;
          _loadPromptList(reset: false);
        } else {
          Fluttertoast.showToast(
            msg: "已经到底了",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
            fontSize: ThemeSize.middleFont,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: ThemeSize.middleGap),
        decoration: ThemeStyle.boxDecoration,
        padding: ThemeStyle.padding,
        child: Column(
          children: _promptList.asMap().entries.map((entry) {
            final index = entry.key;
            final prompt = entry.value;
            final isLast = index == _promptList.length - 1;
            final isSelected = _tempPromptId == prompt.id;

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: isLast ? Colors.transparent : ThemeColors.gray,
                  ),
                ),
              ),
              child: Slidable(
                key: ValueKey(prompt.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.75,
                  children: [
                    // 删除按钮
                    _buildSlidableAction(
                      onPressed: () => _onDeletePrompt(index),
                      backgroundColor: ThemeColors.warn,
                      label: '删除',
                    ),
                    // 编辑按钮
                    _buildSlidableAction(
                      onPressed: () => _onEditPrompt(index),
                      backgroundColor: ThemeColors.primary,
                      label: '编辑',
                    ),
                    // 使用/取消使用按钮
                    _buildSlidableAction(
                      onPressed: () => _onToggleUse(index),
                      backgroundColor: isSelected
                          ? ThemeColors.gray
                          : Colors.green,
                      label: isSelected ? '取消使用' : '使用',
                    ),
                  ],
                ),
                child: ClipRect(child: GestureDetector(
                  onTap: () => _onToggleUse(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: ThemeSize.middleGap,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            prompt.prompt,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: ThemeSize.normalFont,
                              color: isSelected
                                  ? ThemeColors.primary
                                  : ThemeColors.mainTitle,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: ThemeColors.primary,
                            size: ThemeSize.middleIcon,
                          ),
                      ],
                    ),
                  ),
                ))

              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建滑动操作按钮
  /// @date: 2026-09-11
  Widget _buildSlidableAction({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required String label,
  }) {
    return CustomSlidableAction(
      onPressed: (context) => onPressed(),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: ThemeSize.smallMargin),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ThemeSize.normalFont,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 底部按钮
  /// @date: 2026-09-11
  Widget _buildBottomButtons() {
    final canConfirm = _tempPromptId != null;
    return Container(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      color: ThemeColors.white,
      child: Row(
        children: [
          // 取消按钮
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ThemeColors.subTitle),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(ThemeSize.btnHeight / 2),
                ),
                minimumSize: const Size(0, ThemeSize.btnHeight),
              ),
              child: const Text(
                '取消',
                style: TextStyle(
                  color: ThemeColors.subTitle,
                  fontSize: ThemeSize.normalFont,
                ),
              ),
            ),
          ),
          const SizedBox(width: ThemeSize.middleGap),
          // 确定按钮
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: canConfirm ? _onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                canConfirm ? ThemeColors.primary : ThemeColors.gray,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ThemeColors.gray,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(ThemeSize.btnHeight / 2),
                ),
                minimumSize: const Size(0, ThemeSize.btnHeight),
              ),
              child: const Text(
                '确定',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ThemeSize.normalFont,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}