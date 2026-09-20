import 'package:flutter/material.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';

/// @author: wuwenqiang
/// @description: 可复用组件-对话框按钮
/// 高度 ThemeSize.btnHeight，圆角 btnHeight/2
/// 主按钮（确定）：主色调背景 + 白色文字；次按钮（取消）：透明背景 + 灰色边框和文字
/// @date: 2026-09-20
class DialogButtonComponent extends StatelessWidget {
  /// 按钮文案
  final String text;

  /// 点击回调
  final VoidCallback onTap;

  /// 是否为主按钮（确定按钮）
  final bool isPrimary;

  const DialogButtonComponent({
    super.key,
    required this.text,
    required this.onTap,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: ThemeSize.btnHeight,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isPrimary ? ThemeColors.primary : Colors.transparent,
          side: BorderSide(
            color: isPrimary ? ThemeColors.primary : ThemeColors.gray,
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: ThemeSize.normalFont,
            color: isPrimary ? ThemeColors.white : ThemeColors.gray,
          ),
        ),
      ),
    );
  }
}
