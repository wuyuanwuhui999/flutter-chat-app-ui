import 'package:flutter/material.dart';
import 'package:flutter_chat_app/theme/ThemeSize.dart';

class DialogComponent extends StatelessWidget {
  final String? title;
  final Widget content;
  final Widget? leftIcon;
  final Widget? rightIcon; // ✅ 新增：右侧图标
  final Function? onClose;
  final double topMarginRatio;
  final bool showDivider;

  /// 【新增】标题栏自定义内容（如"我的文档 | 公共文档"页签），
  /// 传入后替代 title 文本展示在标题栏正中间（居中对齐）
  final Widget? titleWidget;

  const DialogComponent({
    super.key,
    this.title,
    required this.content,
    this.leftIcon,
    this.rightIcon, // ✅ 新增
    this.onClose,
    this.topMarginRatio = 0.2,
    this.showDivider = true,
    this.titleWidget,
  }) : assert(title != null || titleWidget != null,
            'title 与 titleWidget 至少要传一个');

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topMargin = screenHeight * topMarginRatio;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 灰色透明遮罩层
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (onClose != null) {
                  onClose!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ),

          // 弹出层内容
          Positioned(
            top: topMargin,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(ThemeSize.bigRadius),
                  topRight: Radius.circular(ThemeSize.bigRadius),
                ),
              ),
              child: Column(
                children: [
                  // 标题栏
                  SizedBox(
                    height: ThemeSize.titleBarHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        leftIcon != null ?
                        Align(
                          alignment: Alignment.centerLeft,
                          child: leftIcon,
                        )
                            : const SizedBox(),
                        // 标题（titleWidget 优先：如"我的文档 | 公共文档"页签），整体居中对齐
                        Center(
                          child: titleWidget ??
                              Text(
                                title ?? '',
                                style: const TextStyle(
                                  fontSize: ThemeSize.middleFont,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                        // 关闭按钮 / 自定义右侧图标
                        Align(
                          alignment: Alignment.centerRight,
                          child: rightIcon ??
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  if (onClose != null) {
                                    onClose!();
                                  } else {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                        ),
                      ],
                    ),
                  ),

                  // 分隔线
                  showDivider ? const Divider(height: 1, thickness: 1) : const SizedBox(),

                  // 自定义内容区域
                  Expanded(
                    child: content,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}