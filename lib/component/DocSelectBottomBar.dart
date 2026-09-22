import 'package:flutter/material.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeSize.dart';

/// @author: wuwenqiang
/// @description: 文档选择底部"取消/确定"按钮条
/// 1、"选择文档"弹窗的两个页签（我的文档/公共文档）共用这一条按钮；
/// 2、没有勾选任何文档时"确定"按钮置灰不可点击，有勾选时按钮上显示勾选数量（跨页签合并后的数量）
/// @date: 2026-09-22
class DocSelectBottomBar extends StatelessWidget {
  /// 当前勾选的文档数量
  final int selectedCount;

  /// 点击确定
  final VoidCallback onConfirm;

  /// 点击取消
  final VoidCallback onCancel;

  const DocSelectBottomBar({
    super.key,
    required this.selectedCount,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      decoration: const BoxDecoration(color: ThemeColors.background),
      child: Row(
        children: [
          // 取消按钮
          Expanded(
            flex: 1,
            child: OutlinedButton(
              key: const ValueKey('doc-select-cancel'),
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ThemeColors.subTitle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
                ),
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
              key: const ValueKey('doc-select-confirm'),
              onPressed: selectedCount == 0 ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedCount == 0 ? ThemeColors.gray : ThemeColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ThemeColors.gray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '确定',
                    style: TextStyle(
                      fontSize: ThemeSize.normalFont,
                      color: Colors.white,
                    ),
                  ),
                  if (selectedCount > 0) ...[
                    const SizedBox(width: ThemeSize.miniMargin),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSize.miniMargin,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        selectedCount.toString(),
                        style: const TextStyle(
                          color: ThemeColors.primary,
                          fontSize: ThemeSize.smallFont - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
