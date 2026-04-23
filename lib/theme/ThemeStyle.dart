import 'package:flutter/material.dart';
import './ThemeSize.dart';
import './ThemeColors.dart';

class ThemeStyle {
  static const BoxDecoration boxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(ThemeSize.middleRadius)),
  );

  static const EdgeInsets margin = EdgeInsets.only(bottom: ThemeSize.middleGap);

  static const EdgeInsets padding = EdgeInsets.all(ThemeSize.middleGap);

  static const EdgeInsets paddingBox = EdgeInsets.only(left: ThemeSize.middleGap,right: ThemeSize.middleGap);

  static const TextStyle mainTitleStyle = TextStyle(
      color: ThemeColors.mainTitle,
      fontSize: ThemeSize.bigFont,
      fontWeight: FontWeight.bold);

  static const TextStyle subTitleStyle =
      TextStyle(color: ThemeColors.subTitle, fontSize: ThemeSize.smallFont);

  static const BoxDecoration bottomDecoration = BoxDecoration(
      border: Border(
          bottom: BorderSide(
            // 设置单侧边框的样式
              color: ThemeColors.gray,
              width: 1,
              style: BorderStyle.solid)));

  //列边距
  static const EdgeInsets middleGap = EdgeInsets.only(top: ThemeSize.middleGap,bottom: ThemeSize.middleGap);
}
