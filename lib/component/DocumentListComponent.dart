import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../common/constant.dart';
import '../model/DirectoryModel.dart';
import '../model/DocModel.dart';
import '../model/DocumentCheckModel.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeSize.dart';
import '../utils/HttpUtil.dart';
import 'BottomSelectionDialog.dart';
import 'CustomDialogComponent.dart';
import 'DocPermissionDialog.dart';
import 'DocSelectBottomBar.dart';

/// @author: wuwenqiang
/// @description: 文档列表组件（"选择文档"和"我的文档"对话框共用）
/// 1、先获取文档目录列表，点击目录展开箭头才加载该目录下的文档列表；
/// 2、目录展开时箭头顺时针旋转90度朝下，再次点击收起并还原箭头；
/// 3、文档条目右侧为三个点的操作图标，点击可选择"修改权限"或"删除"
/// [showCheckbox] 是否显示文档复选框（"我的文档"对话框不显示）
/// [showBottomButtons] 是否显示底部"确定/取消"按钮（"我的文档"对话框不显示）
/// [publicMode] 公共文档模式：一次性调用 getPublicDocList 拿到全部公开文档，
///   按 directoryName（文档目录名称）分组显示目录卡片，目录展开时直接显示文档列表（不再请求接口）；
///   该模式下的文档可能属于他人，"三个点"（修改权限/删除）操作入口不显示
/// [checkedIds] 受控勾选集合：由父级（"选择文档"弹窗）统一下发，用于跨页签合并勾选；
///   不传则组件自管理勾选状态（保持原有行为）
/// [onDocChecked] 受控模式下单篇文档的勾选变化回调
/// @date: 2025-09-08
class DocumentListComponent extends StatefulWidget {
  /// 是否显示文档复选框
  final bool showCheckbox;

  /// 是否显示底部确定/取消按钮
  final bool showBottomButtons;

  /// 初始选中的文档ID列表
  final List<String> initialSelectedIds;

  /// 是否为公共文档模式（按目录名称分组、文档随接口一次返回）
  final bool publicMode;

  /// 受控勾选集合（传 null 表示组件自管理勾选）
  final List<String>? checkedIds;

  /// 受控模式下单篇文档勾选变化回调：doc 文档对象，checked 变化后的勾选状态
  final void Function(DocModel doc, bool checked)? onDocChecked;

  /// 选中文档变化回调（复选框模式使用）
  final Function(List<String> selectedIds, List<String> selectedNames)?
      onSelectionChanged;

  /// 点击确定回调（复选框模式使用）
  final Function(List<String> selectedIds, List<String> selectedNames)? onConfirm;

  /// 点击取消回调（复选框模式使用）
  final VoidCallback? onCancel;

  const DocumentListComponent({
    super.key,
    this.showCheckbox = true,
    this.showBottomButtons = true,
    this.initialSelectedIds = const [],
    this.publicMode = false,
    this.checkedIds,
    this.onDocChecked,
    this.onSelectionChanged,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<DocumentListComponent> createState() => _DocumentListComponentState();
}

class _DocumentListComponentState extends State<DocumentListComponent> {
  /// 目录列表（每个目录携带展开状态和按需加载的文档列表）
  List<DocumentCheckModel> directoryList = [];

  /// 目录列表是否加载中
  bool isLoading = true;

  /// 加载失败提示
  String? errorMessage;

  /// 当前选中的文档ID
  List<String> _selectedDocIds = [];

  /// 当前选中的文档名称
  List<String> _selectedDocNames = [];

  late ChatProvider chatProvider;

  @override
  void initState() {
    super.initState();
    // 初始化选中的文档ID列表：受控模式下以父级下发的勾选集合为准
    _selectedDocIds = widget.checkedIds != null
        ? List.from(widget.checkedIds!)
        : List.from(widget.initialSelectedIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDirectoryList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 受控模式下跟随父级下发的勾选集合（另一个页签的勾选变化也会同步过来）
  /// @date: 2026-09-22
  @override
  void didUpdateWidget(covariant DocumentListComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checkedIds == null) return;
    if (_sameIds(widget.checkedIds!, _selectedDocIds)) return;
    _selectedDocIds = List.from(widget.checkedIds!);
    _applyCheckedState();
  }

  /// @author: wuwenqiang
  /// @description: 按当前勾选集合回显所有已加载文档的复选框状态
  /// @date: 2026-09-22
  void _applyCheckedState() {
    for (var directory in directoryList) {
      for (var doc in directory.docList) {
        doc.checked = _selectedDocIds.contains(doc.id);
      }
    }
  }

  /// 比较两组文档ID是否完全一致（顺序忽略）
  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (final String id in a) {
      if (!b.contains(id)) return false;
    }
    return true;
  }

  /// @author: wuwenqiang
  /// @description: 获取文档目录列表（只获取目录，文档列表在目录展开时才加载）
  /// @date: 2026-09-20
  void _loadDirectoryList() {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    chatProvider = Provider.of<ChatProvider>(context, listen: false);
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

    // 公共文档模式：一次性拉取全部公开文档后按目录名称分组，不需要目录列表接口
    if (widget.publicMode) {
      _loadPublicDocList(tenantId);
      return;
    }

    getDirectoryListService(tenantId).then((res) {
      if (!mounted) return;

      // 目录列表完全以后端返回的为准（不再拼装"默认文件夹"）
      final List<DocumentCheckModel> tempList = [];
      for (var item in res.data) {
        final dir = DirectoryModel.fromJson(item);
        tempList.add(DocumentCheckModel(
          expand: false,
          directoryId: dir.id,
          directoryName: dir.directory,
          docList: [],
        ));
      }

      setState(() {
        directoryList = tempList;
        isLoading = false;
      });
    }).catchError((error) {
      debugPrint('加载目录列表失败: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '加载目录失败，请重试';
        });
      }
    });
  }

  /// @author: wuwenqiang
  /// @description: 公共文档模式：调用 getPublicDocList 一次性拿到全部公开文档（租户内公开+公司内公开），
  /// 按 directoryName（文档目录名称）分组，每个分组直接带上文档列表（loaded=true），
  /// 点击目录名称展开时直接显示对应文档，不再请求接口
  /// @date: 2026-09-22
  void _loadPublicDocList(String tenantId) {
    final String companyId = chatProvider.currentCompanyId;

    getPublicDocListService(tenantId, companyId).then((res) {
      if (!mounted) return;

      final List<DocumentCheckModel> tempList = [];
      // 按目录名称分组，key 为目录名称
      final Map<String, DocumentCheckModel> groupMap = {};

      for (var item in res.data) {
        final DocModel docModel = DocModel.fromJson(item);
        // 回显勾选状态
        docModel.checked = _selectedDocIds.contains(docModel.id);

        // 后端未返回目录名称的文档归入"默认文件夹"分组
        final String directoryName = docModel.directoryName.isEmpty
            ? DEFAULT_DIRECTORY_NAME
            : docModel.directoryName;

        DocumentCheckModel? group = groupMap[directoryName];
        if (group == null) {
          group = DocumentCheckModel(
            expand: false,
            // 公共文档按目录名称分组，没有目录id，用目录名称作为分组标识
            directoryId: directoryName,
            directoryName: directoryName,
            docList: [],
            // 文档随接口一起返回，展开时直接显示，不再请求接口
            loaded: true,
          );
          groupMap[directoryName] = group;
          tempList.add(group);
        }
        group.docList.add(docModel);
      }

      setState(() {
        directoryList = tempList;
        isLoading = false;
      });
    }).catchError((error) {
      debugPrint('加载公共文档列表失败: $error');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        // 后端会返回"无权查询：当前用户不在该租户/公司内"等提示
        errorMessage = parseResponseErrorMsg(error);
      });
    });
  }

  /// @author: wuwenqiang
  /// @description: 点击目录名称/展开箭头：首次展开时加载该目录下的文档列表，再次点击收起
  /// 公共文档模式下文档已随接口返回（loaded=true），展开时直接显示不再请求接口
  /// @date: 2026-09-20
  void _onToggleDirectory(int index) {
    final DocumentCheckModel directory = directoryList[index];

    // 已展开则收起，箭头还原为向右
    if (directory.expand) {
      setState(() {
        directory.expand = false;
      });
      return;
    }

    setState(() {
      directory.expand = true;
    });

    // 已加载过该目录的文档列表，不重复请求
    if (directory.loaded || directory.loading) {
      return;
    }

    final tenantId = chatProvider.currentTenantId;
    setState(() {
      directory.loading = true;
    });

    getDocListByDirIdService(tenantId, directory.directoryId).then((res) {
      if (!mounted) return;

      final List<DocModel> docs = [];
      for (var doc in res.data) {
        final docModel = DocModel.fromJson(doc);
        // 回显勾选状态
        docModel.checked = _selectedDocIds.contains(docModel.id);
        docs.add(docModel);
      }

      setState(() {
        directory.docList = docs;
        directory.loading = false;
        directory.loaded = true;
      });
    }).catchError((error) {
      debugPrint('加载文档列表失败: $error');
      if (!mounted) return;
      setState(() {
        directory.loading = false;
      });
      _showToast('加载文档列表失败');
    });
  }

  /// @author: wuwenqiang
  /// @description: 点击文档条目上的三个点图标：弹出"修改权限/删除"操作选项
  /// @date: 2026-09-20
  void _onDocOperation(int directoryIndex, int docIndex) {
    BottomSelectionDialog.show(
      context: context,
      options: const ['修改权限', '删除'],
      onTap: (option, index) {
        if (index == 0) {
          _onUpdateDocPermission(directoryIndex, docIndex);
        } else if (index == 1) {
          _onDeleteDoc(directoryIndex, docIndex);
        }
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 修改文档权限（弹出修改权限对话框，成功后回显新权限）
  /// @date: 2026-09-20
  Future<void> _onUpdateDocPermission(int directoryIndex, int docIndex) async {
    final DocModel doc = directoryList[directoryIndex].docList[docIndex];
    final String? newPermission = await DocPermissionDialog.show(
      context: context,
      doc: doc,
    );

    if (newPermission == null || !mounted) return;
    setState(() {
      doc.permission = newPermission;
    });
  }

  /// @author: wuwenqiang
  /// @description: 删除文档（先弹出确认对话框）
  /// @date: 2026-09-20
  void _onDeleteDoc(int directoryIndex, int docIndex) {
    final DocModel doc = directoryList[directoryIndex].docList[docIndex];
    CustomDialogComponent(
      context: context,
      name: '提示',
      builder: (BuildContext context) => Text('是否删除文档：${doc.name}'),
      okCallback: () => _deleteDoc(directoryIndex, docIndex),
    ).show();
  }

  /// @author: wuwenqiang
  /// @description: 调用删除文档接口，data大于0表示删除成功，成功/失败都提示后端返回的msg
  /// @date: 2026-09-20
  Future<void> _deleteDoc(int directoryIndex, int docIndex) async {
    final DocModel doc = directoryList[directoryIndex].docList[docIndex];
    try {
      final res = await deleteMyDocumentService(doc.id);
      final int? rows = res.data == null ? null : int.tryParse(res.data.toString());
      if (rows != null && rows > 0) {
        if (mounted) {
          setState(() {
            directoryList[directoryIndex].docList.removeAt(docIndex);
          });
          if (widget.checkedIds != null) {
            // 受控模式：文档已删除，把它从父级的勾选集合里摘掉
            widget.onDocChecked?.call(doc, false);
          } else {
            _notifySelectionChanged();
          }
        }
        _showToast(res.msg ?? '删除文档成功');
      } else {
        _showToast(res.msg ?? '删除文档失败');
      }
    } catch (e) {
      // 失败时提示后端返回的msg
      _showToast(parseResponseErrorMsg(e));
    }
  }

  /// @author: wuwenqiang
  /// @description: 通知选中文档变化
  /// @date: 2026-09-05
  void _notifySelectionChanged() {
    final List<String> selectedIds = [];
    final List<String> selectedNames = [];
    for (var directory in directoryList) {
      for (var doc in directory.docList) {
        if (doc.checked) {
          selectedIds.add(doc.id);
          selectedNames.add(doc.name);
        }
      }
    }
    _selectedDocIds = selectedIds;
    _selectedDocNames = selectedNames;
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(selectedIds, selectedNames);
    }
  }

  /// @author: wuwenqiang
  /// @description: 切换文档选中状态
  /// @date: 2025-09-08
  void _toggleDocCheck(int directoryIndex, int docIndex) {
    setState(() {
      final DocModel doc = directoryList[directoryIndex].docList[docIndex];
      doc.checked = !doc.checked;
      if (widget.checkedIds != null) {
        // 受控模式：把单篇的勾选变化抛给父级，由父级统一下发新的勾选集合（跨页签合并）
        widget.onDocChecked?.call(doc, doc.checked);
      } else {
        _notifySelectionChanged();
      }
    });
  }

  /// @author: wuwenqiang
  /// @description: 全选/取消全选某个目录下已加载的所有文档
  /// @date: 2025-09-08
  void _toggleGroupAll(int directoryIndex) {
    final DocumentCheckModel directory = directoryList[directoryIndex];
    final bool allChecked = directory.docList.every((doc) => doc.checked);

    setState(() {
      for (var doc in directory.docList) {
        doc.checked = !allChecked;
        if (widget.checkedIds != null) {
          // 受控模式：逐篇抛给父级，由父级统一下发新的勾选集合
          widget.onDocChecked?.call(doc, doc.checked);
        }
      }
      if (widget.checkedIds == null) {
        _notifySelectionChanged();
      }
    });
  }

  /// @author: wuwenqiang
  /// @description: 确认选择
  /// @date: 2026-09-05
  void _onConfirm() {
    if (_selectedDocIds.isEmpty) {
      _showToast('请至少选择一篇文档');
      return;
    }
    if (widget.onConfirm != null) {
      widget.onConfirm!(_selectedDocIds, _selectedDocNames);
    }
  }

  /// @author: wuwenqiang
  /// @description: 统一提示
  /// @date: 2026-09-20
  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      fontSize: ThemeSize.middleFont,
    );
  }

  /// @author: wuwenqiang
  /// @description: 根据文件扩展名获取对应的图标
  /// 【修复】原实现引用的 icon_pdf.png 等资源文件在项目中不存在（也未在pubspec声明），
  /// 会导致文档图标加载失败，这里改用内置Material图标
  /// @date: 2026-09-20
  IconData _getDocIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
        return Icons.description;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// @author: wuwenqiang
  /// @description: 构建目录条目（目录名称 + 展开箭头 + 展开后的文档列表）
  /// @date: 2026-09-20
  Widget _buildDirectoryItem(int index, DocumentCheckModel directory) {
    final bool isLast = index == directoryList.length - 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: index == 0 ? 0 : ThemeSize.middleGap,
        bottom: isLast ? 0 : ThemeSize.middleGap,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: isLast ? Colors.transparent : ThemeColors.gray,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目录名称 + 展开箭头（整行可点击展开/收起）
          GestureDetector(
            onTap: () => _onToggleDirectory(index),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    directory.directoryName,
                    style: const TextStyle(
                      fontSize: ThemeSize.normalFont,
                      fontWeight: FontWeight.w500,
                      color: ThemeColors.mainTitle,
                    ),
                  ),
                ),
                // 全选/取消全选按钮（仅复选框模式且该目录文档已加载时显示）
                if (widget.showCheckbox &&
                    directory.loaded &&
                    directory.docList.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _toggleGroupAll(index),
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
                        directory.docList.every((doc) => doc.checked)
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
                ],
                // 展开箭头：折叠时向右，展开时顺时针旋转90度朝下
                Transform.rotate(
                  key: ValueKey('dir-arrow-${directory.directoryId}'),
                  angle: directory.expand ? pi / 2 : 0,
                  child: Opacity(
                    opacity: ThemeSize.opacity,
                    child: Image.asset(
                      'lib/assets/images/icon_arrow.png',
                      width: ThemeSize.smallIcon,
                      height: ThemeSize.smallIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 文档列表（目录展开后才显示，文档列表在展开时按需加载）
          if (directory.expand) ...[
            if (directory.loading)
              const Padding(
                padding: EdgeInsets.only(top: ThemeSize.smallMargin),
                child: Center(
                  child: SizedBox(
                    width: ThemeSize.smallIcon,
                    height: ThemeSize.smallIcon,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (directory.docList.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: ThemeSize.smallMargin),
                child: Text(
                  '暂无文档',
                  style: TextStyle(
                    color: ThemeColors.subTitle,
                    fontSize: ThemeSize.smallFont,
                  ),
                ),
              )
            else
              ...directory.docList.asMap().entries.map((entry) {
                return _buildDocItem(index, entry.key, entry.value);
              }),
          ],
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建文档条目（文档图标 + 文档名称 + 三个点操作图标 + 可选复选框）
  /// @date: 2026-09-20
  Widget _buildDocItem(int directoryIndex, int docIndex, DocModel doc) {
    return Padding(
      padding: const EdgeInsets.only(
        top: ThemeSize.smallMargin,
        left: ThemeSize.smallMargin,
      ),
      child: Row(
        children: [
          // 文档图标
          Icon(
            _getDocIcon(doc.ext),
            size: ThemeSize.smallIcon,
            color: ThemeColors.primary,
          ),
          const SizedBox(width: ThemeSize.smallMargin),
          Expanded(
            child: Text(
              doc.name,
              style: const TextStyle(
                color: ThemeColors.mainTitle,
                fontSize: ThemeSize.normalFont,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ThemeSize.smallMargin),
          // 操作图标（三个点）：修改权限 / 删除
          // 公共文档页签里的文档可能属于他人（后端只允许修改/删除本人文档），因此不显示该操作入口
          if (!widget.publicMode)
            GestureDetector(
              key: ValueKey('doc-more-${doc.id}'),
              onTap: () => _onDocOperation(directoryIndex, docIndex),
              behavior: HitTestBehavior.opaque,
              child: const Opacity(
                opacity: ThemeSize.opacity,
                child: Icon(
                  Icons.more_horiz,
                  size: ThemeSize.middleIcon,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
          // 复选框
          if (widget.showCheckbox) ...[
            const SizedBox(width: ThemeSize.smallMargin),
            GestureDetector(
              key: ValueKey('doc-check-${doc.id}'),
              onTap: () => _toggleDocCheck(directoryIndex, docIndex),
              child: Container(
                width: ThemeSize.radioSize,
                height: ThemeSize.radioSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: doc.checked ? ThemeColors.primary : ThemeColors.gray,
                    width: 2,
                  ),
                  color: doc.checked ? ThemeColors.primary : Colors.transparent,
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
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建底部"确定/取消"按钮（"我的文档"对话框不显示）
  /// 按钮条已抽到 DocSelectBottomBar，"选择文档"弹窗的两个页签共用同一条按钮
  /// @date: 2026-09-20
  Widget _buildBottomButtons() {
    return DocSelectBottomBar(
      selectedCount: _selectedDocIds.length,
      onConfirm: _onConfirm,
      onCancel: () {
        if (widget.onCancel != null) {
          widget.onCancel!();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context, listen: true);

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
              onPressed: _loadDirectoryList,
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

    if (directoryList.isEmpty) {
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

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: ThemeColors.background),
            child: SingleChildScrollView(
              child: Container(
                decoration: ThemeStyle.boxDecoration,
                padding: ThemeStyle.padding,
                margin: ThemeStyle.padding,
                child: Column(
                  children: directoryList
                      .asMap()
                      .entries
                      .map((entry) =>
                          _buildDirectoryItem(entry.key, entry.value))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        // 底部按钮（"我的文档"对话框不显示）
        if (widget.showBottomButtons) _buildBottomButtons(),
      ],
    );
  }
}
