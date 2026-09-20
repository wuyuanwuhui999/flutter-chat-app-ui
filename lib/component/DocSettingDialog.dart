import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../model/DocSettingModel.dart';
import '../model/SelectOptionModel.dart';
import '../theme/Dimens.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import 'BottomSelectionDialog.dart';
import 'DialogButtonComponent.dart';
import 'SelectRowComponent.dart';

/// @author: wuwenqiang
/// @description: 文档设置对话框（权限 / 分割模式 / 分割大小）
/// 选择文档之后弹出，点击确定返回用户选择的设置，点击取消返回 null
/// @date: 2026-09-20
class DocSettingDialog {
  DocSettingDialog._();

  /// 弹出文档设置对话框
  /// [context] 上下文
  /// [initialSetting] 初始设置（不传则使用默认值：私密 + 递归字符分割 + 1000）
  /// 返回值：确定时返回 [DocSettingModel]，取消时返回 null
  static Future<DocSettingModel?> show({
    required BuildContext context,
    DocSettingModel? initialSetting,
  }) {
    return showDialog<DocSettingModel>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _DocSettingDialogWidget(
          initialSetting: initialSetting ?? DocSettingModel(),
        );
      },
    );
  }
}

/// 文档设置对话框内部实现
class _DocSettingDialogWidget extends StatefulWidget {
  /// 初始设置
  final DocSettingModel initialSetting;

  const _DocSettingDialogWidget({
    required this.initialSetting,
  });

  @override
  State<_DocSettingDialogWidget> createState() =>
      _DocSettingDialogWidgetState();
}

class _DocSettingDialogWidgetState extends State<_DocSettingDialogWidget> {
  /// 文档权限
  late String permission;

  /// 分割模式
  late String splitMethod;

  /// 分割大小输入框控制器（默认值1000）
  late TextEditingController chunkSizeController;

  @override
  void initState() {
    super.initState();
    permission = widget.initialSetting.permission;
    splitMethod = widget.initialSetting.splitMethod;
    chunkSizeController = TextEditingController(
      text: '${widget.initialSetting.chunkSize}',
    );
  }

  @override
  void dispose() {
    chunkSizeController.dispose();
    super.dispose();
  }

  /// @author: wuwenqiang
  /// @description: 选择文档权限（弹出底部选择列表）
  /// @date: 2026-09-20
  void _onSelectPermission() {
    BottomSelectionDialog.show(
      context: context,
      options: DOC_PERMISSION_OPTIONS
          .map((SelectOptionModel item) => item.label)
          .toList(),
      selectedOption: DocSettingModel.labelOf(
        DOC_PERMISSION_OPTIONS,
        permission,
      ),
      onTap: (label, index) {
        setState(() {
          permission = DOC_PERMISSION_OPTIONS[index].value;
        });
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 选择分割模式（弹出底部选择列表）
  /// @date: 2026-09-20
  void _onSelectSplitMethod() {
    BottomSelectionDialog.show(
      context: context,
      options: DocSettingModel.splitMethodOptions
          .map((SelectOptionModel item) => item.label)
          .toList(),
      selectedOption: DocSettingModel.labelOf(
        DocSettingModel.splitMethodOptions,
        splitMethod,
      ),
      onTap: (label, index) {
        setState(() {
          splitMethod = DocSettingModel.splitMethodOptions[index].value;
        });
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 点击确定，校验分割大小并返回文档设置
  /// @date: 2026-09-20
  void _onConfirm() {
    int chunkSize = DocSettingModel.defaultChunkSize;
    // 固定长度分割时，分割大小必填且必须为正整数
    if (splitMethod == DocSettingModel.splitMethodFixed) {
      final int? inputSize = int.tryParse(chunkSizeController.text.trim());
      if (inputSize == null || inputSize <= 0) {
        Fluttertoast.showToast(
          msg: "请输入正确的分割大小",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: ThemeSize.middleFont,
          backgroundColor: ThemeColors.warn,
          textColor: ThemeColors.white,
        );
        return;
      }
      chunkSize = inputSize;
    }

    Navigator.of(context).pop(
      DocSettingModel(
        permission: permission,
        splitMethod: splitMethod,
        chunkSize: chunkSize,
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建分割大小输入行（只对固定长度分割可见）
  /// @date: 2026-09-20
  Widget _buildChunkSizeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeSize.middleGap),
      child: Row(
        children: [
          const Text(
            '分割大小',
            style: TextStyle(
              fontSize: ThemeSize.normalFont,
              color: ThemeColors.mainTitle,
            ),
          ),
          const SizedBox(width: ThemeSize.middleGap),
          Expanded(
            child: SizedBox(
              height: ThemeSize.inputHeight,
              child: TextField(
                controller: chunkSizeController,
                keyboardType: TextInputType.number,
                // 只允许输入数字
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: ThemeSize.normalFont,
                  color: ThemeColors.mainTitle,
                ),
                decoration: InputDecoration(
                  hintText: '请输入分割大小',
                  hintStyle: const TextStyle(
                    fontSize: ThemeSize.normalFont,
                    color: ThemeColors.subTitle,
                  ),
                  filled: true,
                  fillColor: ThemeColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ThemeSize.middleGap,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ThemeSize.inputHeight / 2,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ThemeSize.inputHeight / 2,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ThemeSize.inputHeight / 2,
                    ),
                    borderSide: const BorderSide(
                      color: ThemeColors.primary,
                      width: ThemeSize.borderWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
                '文档设置',
                style: TextStyle(
                  fontSize: ThemeSize.bigFont,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
            const SizedBox(height: ThemeSize.middleGap),
            // 权限下拉框
            SelectRowComponent(
              label: '权限',
              value: DocSettingModel.labelOf(
                DOC_PERMISSION_OPTIONS,
                permission,
              ),
              onTap: _onSelectPermission,
            ),
            const Divider(height: 1, color: ThemeColors.gray),
            // 分割模式下拉框
            SelectRowComponent(
              label: '分割模式',
              value: DocSettingModel.labelOf(
                DocSettingModel.splitMethodOptions,
                splitMethod,
              ),
              onTap: _onSelectSplitMethod,
            ),
            // 分割大小输入框，只对固定长度分割（fixed）可见
            if (splitMethod == DocSettingModel.splitMethodFixed) ...[
              const Divider(height: 1, color: ThemeColors.gray),
              _buildChunkSizeRow(),
            ],
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
