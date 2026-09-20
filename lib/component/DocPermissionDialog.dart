import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../model/DocModel.dart';
import '../model/DocSettingModel.dart';
import '../model/SelectOptionModel.dart';
import '../service/serverMethod.dart';
import '../theme/Dimens.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../utils/HttpUtil.dart';
import 'BottomSelectionDialog.dart';
import 'DialogButtonComponent.dart';
import 'SelectRowComponent.dart';

/// @author: wuwenqiang
/// @description: 修改文档权限对话框（权限下拉框默认回显文档当前的permission）
/// 点击确定调用 /service/chat/updateDocPermission/{docId}，返回data>0表示修改成功
/// 确定返回新的权限值，取消返回 null
/// @date: 2026-09-20
class DocPermissionDialog {
  DocPermissionDialog._();

  /// 弹出修改权限对话框
  /// [context] 上下文
  /// [doc] 当前操作的文档（用其中的id和permission）
  /// 返回值：修改成功时返回新的权限值，取消或失败返回 null
  static Future<String?> show({
    required BuildContext context,
    required DocModel doc,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _DocPermissionDialogWidget(
          docId: doc.id,
          initialPermission: doc.permission,
        );
      },
    );
  }
}

/// 修改权限对话框内部实现
class _DocPermissionDialogWidget extends StatefulWidget {
  /// 文档id
  final String docId;

  /// 文档当前权限（用于下拉框默认回显）
  final String initialPermission;

  const _DocPermissionDialogWidget({
    required this.docId,
    required this.initialPermission,
  });

  @override
  State<_DocPermissionDialogWidget> createState() =>
      _DocPermissionDialogWidgetState();
}

class _DocPermissionDialogWidgetState
    extends State<_DocPermissionDialogWidget> {
  /// 当前选中的文档权限
  late String permission;

  /// 是否正在提交（防止重复点击确定）
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 默认值使用文档条目中的 permission 字段回显
    permission = widget.initialPermission;
  }

  /// @author: wuwenqiang
  /// @description: 选择文档权限（弹出底部选择列表，选项为 DOC_PERMISSION_OPTIONS）
  /// @date: 2026-09-20
  void _onSelectPermission() {
    BottomSelectionDialog.show(
      context: context,
      options: DOC_PERMISSION_OPTIONS
          .map((SelectOptionModel item) => item.label)
          .toList(),
      selectedOption: DocSettingModel.labelOf(DOC_PERMISSION_OPTIONS, permission),
      onTap: (label, index) {
        setState(() {
          permission = DOC_PERMISSION_OPTIONS[index].value;
        });
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 点击确定，调用修改文档权限接口
  /// 返回data大于0表示修改成功，成功/失败都提示后端返回的msg
  /// @date: 2026-09-20
  Future<void> _onConfirm() async {
    if (isSubmitting) return;
    setState(() {
      isSubmitting = true;
    });

    try {
      final res = await updateDocPermissionService(widget.docId, permission);
      // data大于0表示修改成功
      final int? rows = res.data == null ? null : int.tryParse(res.data.toString());
      if (rows != null && rows > 0) {
        _showToast(res.msg ?? '文档权限修改成功');
        if (mounted) {
          Navigator.of(context).pop(permission);
        }
      } else {
        _showToast(res.msg ?? '文档权限修改失败');
      }
    } catch (e) {
      // 失败时提示后端返回的msg
      _showToast(parseResponseErrorMsg(e));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeColors.white,
      insetPadding: const EdgeInsets.all(ThemeSize.middleGap),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(Dimens.moduleBorderRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ThemeSize.middleGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Center(
              child: Text(
                '修改权限',
                style: TextStyle(
                  fontSize: ThemeSize.bigFont,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
            const SizedBox(height: ThemeSize.middleGap),
            // 权限下拉框（默认回显文档当前的permission）
            SelectRowComponent(
              label: '权限',
              value: DocSettingModel.labelOf(DOC_PERMISSION_OPTIONS, permission),
              onTap: _onSelectPermission,
            ),
            const SizedBox(height: ThemeSize.middleGap),
            // 确定 / 取消 按钮
            Row(
              children: [
                Expanded(
                  child: DialogButtonComponent(
                    text: '取消',
                    isPrimary: false,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: ThemeSize.middleGap),
                Expanded(
                  child: DialogButtonComponent(
                    text: '确定',
                    onTap: _onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
