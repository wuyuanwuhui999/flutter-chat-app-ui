import 'package:flutter/material.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeSize.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../model/DocModel.dart';
import 'DialogComponent.dart';
import 'DocSelectBottomBar.dart';
import 'DocumentListComponent.dart';

/// @author: wuwenqiang
/// @description: "选择文档"对话框
/// 1、标题栏为"我的文档 ｜ 公共文档"两个居中的页签，默认激活"我的文档"（主色+加粗），未激活的为黑色正文色；
/// 2、默认显示"我的文档"页签（按目录按需加载，逻辑不变）；点击"公共文档"页签时才调用
///    /service/chat/getPublicDocList?tenantId={tenantId}&companyId={companyId}；
/// 3、公共文档页签按 directoryName（文档目录名称）分组显示目录卡片，点击展开直接显示对应文档列表，不再请求接口；
/// 4、两个页签用 IndexedStack 保活：来回切换不会丢失目录展开状态和已加载数据；
/// 5、两个页签的勾选结果合并（同一条"确定/取消"按钮，数量为合并后的数量），
///    确定返回 {docIds, docNames}，取消/关闭返回 null
/// @date: 2026-09-22
class DocSelectDialog extends StatefulWidget {
  /// 打开弹窗时已选中的文档ID（回显勾选状态，确定时默认带上）
  final List<String> initialSelectedIds;

  /// 与 initialSelectedIds 一一对应的文档名称
  final List<String> initialSelectedNames;

  /// 勾选变化回调（返回两个页签合并后的文档ID与名称）
  final Function(List<String> selectedIds, List<String> selectedNames)?
      onSelectionChanged;

  const DocSelectDialog({
    super.key,
    this.initialSelectedIds = const [],
    this.initialSelectedNames = const [],
    this.onSelectionChanged,
  });

  @override
  State<DocSelectDialog> createState() => _DocSelectDialogState();
}

class _DocSelectDialogState extends State<DocSelectDialog> {
  /// 页签下标：我的文档
  static const int _tabMine = 0;

  /// 页签下标：公共文档
  static const int _tabPublic = 1;

  /// 当前激活的页签，默认"我的文档"
  int _activeTab = _tabMine;

  /// 公共文档页签是否已经打开过：首次点击才创建（触发一次接口调用），之后保活不再重复请求
  bool _publicTabVisited = false;

  /// 勾选的文档ID（两个页签合并后的结果，保持勾选顺序）
  final List<String> _selectedIds = [];

  /// 文档ID -> 文档名称（确定时一起返回给调用方）
  final Map<String, String> _docNameById = {};

  @override
  void initState() {
    super.initState();
    // 回显打开弹窗前的勾选
    for (int i = 0; i < widget.initialSelectedIds.length; i++) {
      final String id = widget.initialSelectedIds[i];
      if (id.isEmpty || _selectedIds.contains(id)) continue;
      _selectedIds.add(id);
      _docNameById[id] = i < widget.initialSelectedNames.length
          ? widget.initialSelectedNames[i]
          : '';
    }
  }

  /// 下发给两个页签的受控勾选集合（保证跨页签勾选一致）
  List<String> get _checkedIds => List<String>.from(_selectedIds);

  /// 与 _selectedIds 一一对应的文档名称
  List<String> get _selectedNames =>
      _selectedIds.map((id) => _docNameById[id] ?? '').toList();

  /// @author: wuwenqiang
  /// @description: 切换页签；首次切到"公共文档"才创建该页签，从而只调用一次公开文档接口
  /// @date: 2026-09-22
  void _onTabChanged(int tab) {
    if (tab == _activeTab) return;
    setState(() {
      _activeTab = tab;
      if (tab == _tabPublic) {
        _publicTabVisited = true;
      }
    });
  }

  /// @author: wuwenqiang
  /// @description: 页签内某篇文档勾选变化：更新合并后的勾选集合
  /// @date: 2026-09-22
  void _onDocChecked(DocModel doc, bool checked) {
    setState(() {
      if (checked) {
        if (!_selectedIds.contains(doc.id)) {
          _selectedIds.add(doc.id);
        }
        _docNameById[doc.id] = doc.name;
      } else {
        _selectedIds.remove(doc.id);
        _docNameById.remove(doc.id);
      }
    });
    widget.onSelectionChanged?.call(_checkedIds, _selectedNames);
  }

  /// @author: wuwenqiang
  /// @description: 确定：把两个页签合并后的勾选结果返回给调用方
  /// @date: 2026-09-22
  void _onConfirm() {
    if (_selectedIds.isEmpty) {
      _showToast('请至少选择一篇文档');
      return;
    }
    Navigator.of(context).pop({
      'docIds': _checkedIds,
      'docNames': _selectedNames,
    });
  }

  /// @author: wuwenqiang
  /// @description: 取消：关闭弹窗并返回 null
  /// @date: 2026-09-22
  void _onCancel() {
    Navigator.of(context).pop(null);
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      fontSize: ThemeSize.middleFont,
    );
  }

  /// @author: wuwenqiang
  /// @description: 标题栏页签："我的文档 ｜ 公共文档"，整体居中对齐
  /// @date: 2026-09-22
  Widget _buildTabBar() {
    return Row(
      key: const ValueKey('doc-select-tab-bar'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabItem('我的文档', _tabMine),
        const Text(
          '｜',
          style: TextStyle(fontSize: ThemeSize.middleFont, color: ThemeColors.gray),
        ),
        _buildTabItem('公共文档', _tabPublic),
      ],
    );
  }

  /// 单个页签：激活为主色+加粗，未激活为黑色正文色
  Widget _buildTabItem(String text, int tab) {
    final bool active = _activeTab == tab;
    return GestureDetector(
      key: ValueKey('doc-select-tab-$tab'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabChanged(tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ThemeSize.miniMargin),
        child: Text(
          text,
          style: TextStyle(
            fontSize: ThemeSize.middleFont,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? ThemeColors.primary : ThemeColors.mainTitle,
          ),
        ),
      ),
    );
  }

  /// 页签内容：我的文档（按目录按需加载）/ 公共文档（一次拉全量后按目录名称分组）
  Widget _buildDocList(Key key, bool publicMode) {
    return DocumentListComponent(
      key: key,
      publicMode: publicMode,
      showCheckbox: true,
      // 底部按钮由弹窗统一提供（两个页签共用一条，数量为合并后的勾选数量）
      showBottomButtons: false,
      checkedIds: _checkedIds,
      onDocChecked: _onDocChecked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DialogComponent(
      showDivider: false,
      titleWidget: _buildTabBar(),
      content: Column(
        children: [
          Expanded(
            // IndexedStack 保活：切换页签不重建列表，目录展开状态与勾选状态都保留
            child: IndexedStack(
              index: _activeTab,
              children: [
                _buildDocList(const ValueKey('doc-select-list-mine'), false),
                _publicTabVisited
                    ? _buildDocList(const ValueKey('doc-select-list-public'), true)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          DocSelectBottomBar(
            selectedCount: _selectedIds.length,
            onConfirm: _onConfirm,
            onCancel: _onCancel,
          ),
        ],
      ),
    );
  }
}
