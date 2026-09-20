import 'package:flutter/material.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';

/// @author: wuwenqiang
/// @description: 可复用组件-下拉选择行（左侧标题、右侧当前值、右侧下拉箭头），点击弹出选择列表
/// @date: 2026-09-20
class SelectRowComponent extends StatelessWidget {
  /// 左侧标题
  final String label;

  /// 右侧当前选中项的展示文案
  final String value;

  /// 点击回调（一般用来弹出选择列表）
  final VoidCallback onTap;

  const SelectRowComponent({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ThemeSize.middleGap),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: ThemeSize.normalFont,
                color: ThemeColors.mainTitle,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: ThemeSize.normalFont,
                color: ThemeColors.subTitle,
              ),
            ),
            const SizedBox(width: ThemeSize.middleGap),
            // 下拉箭头图标（透明度0.5）
            Opacity(
              opacity: ThemeSize.opacity,
              child: Image.asset(
                'lib/assets/images/icon_arrow.png',
                width: ThemeSize.smallIcon,
                height: ThemeSize.smallIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
