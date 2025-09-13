import 'package:flutter/material.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeStyle.dart';

/*-----------------------标题组件------------------------*/
class NavigatorTitleComponent extends StatelessWidget {
  final String title;
  final Widget? icon; // 可选的icon参数

  const NavigatorTitleComponent({
    super.key,
    required this.title,
    this.icon, // icon参数可选
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: ThemeStyle.padding,
        decoration: const BoxDecoration(color: ThemeColors.colorWhite),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Image.asset("lib/assets/images/icon_back.png",
                    width: ThemeSize.smallIcon, height: ThemeSize.smallIcon),
              ),
              Expanded(flex: 1, child: Center(child: Text(title))),
              // 如果icon不为空则显示icon，否则显示SizedBox占位
              icon ?? const SizedBox(
                width: ThemeSize.smallIcon,
                height: ThemeSize.smallIcon,
              ),
            ]));
  }
}
/*-----------------------标题组件------------------------*/