// lib/component/SelectDialogComponent.dart

import 'package:flutter/material.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeStyle.dart';

class BottomSelectionDialog {
  static void show({
    required BuildContext context,
    required List<String> options,
    required Function(String, int) onTap,
    String? selectedOption,
  }) {
    const divider = Divider(height: 1, color: ThemeColors.gray);

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeSize.middleRadius),
        ),
      ),
      builder: (ctx) {
        // 获取底部安全区域高度
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        // 获取屏幕高度
        final screenHeight = MediaQuery.of(ctx).size.height;

        return Container(
          padding: EdgeInsets.only(
            bottom: ThemeSize.middleGap + bottomPadding,
          ),
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖动指示器
              Container(
                margin: const EdgeInsets.only(top: ThemeSize.smallMargin),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeColors.gray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: ThemeSize.smallMargin),
              // ✅ 选项列表卡片 - 使用 Flexible 配合 ConstrainedBox
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // 最大高度 = 总可用高度 - 固定元素高度
                    maxHeight: screenHeight * 0.8 -
                        ThemeSize.smallMargin * 2 -
                        ThemeSize.middleGap * 3 -
                        50, // 减去顶部指示器、间隔、取消按钮等固定高度
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: ThemeSize.middleGap,
                    ),
                    decoration: const BoxDecoration(
                      color: ThemeColors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(ThemeSize.middleRadius),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (context, index) => divider,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option == selectedOption;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            onTap(option, index);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ThemeSize.middleGap,
                              vertical: ThemeSize.middleGap,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  option,
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
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: ThemeColors.primary,
                                    size: ThemeSize.middleIcon,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 取消按钮与模型列表间隔
              const SizedBox(height: ThemeSize.middleGap),
              // ✅ 取消按钮
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: ThemeSize.middleGap,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(ThemeSize.middleRadius),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.all(
                    Radius.circular(ThemeSize.middleRadius),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: ThemeSize.middleGap,
                    ),
                    child: const Center(
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: ThemeSize.normalFont,
                          color: ThemeColors.subTitle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ✅ 底部额外留白
              const SizedBox(height: ThemeSize.middleGap),
            ],
          ),
        );
      },
    );
  }
}