import 'package:flutter/material.dart';
import './ThemeSize.dart';
import './ThemeColors.dart';

class ThemeStyle {
  static const BoxDecoration boxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(ThemeSize.middleRadius)),
  );

  static const EdgeInsets margin = EdgeInsets.only(bottom: ThemeSize.middleMargin);

  static const EdgeInsets padding = EdgeInsets.all(ThemeSize.middleMargin);

  static const EdgeInsets paddingBox = EdgeInsets.only(left: ThemeSize.middleMargin,right: ThemeSize.middleMargin);

  static const TextStyle mainTitleStyle = TextStyle(
      color: ThemeColors.mainTitle,
      fontSize: ThemeSize.bigFontSize,
      fontWeight: FontWeight.bold);

  static const TextStyle subTitleStyle =
      TextStyle(color: ThemeColors.subTitle, fontSize: ThemeSize.smallFontSize);

  static const BoxDecoration bottomDecoration = BoxDecoration(
      border: Border(
          bottom: BorderSide(
            // 设置单侧边框的样式
              color: ThemeColors.gray,
              width: 1,
              style: BorderStyle.solid)));

  //列边距
  static const EdgeInsets middleMargin = EdgeInsets.only(top: ThemeSize.middleMargin,bottom: ThemeSize.middleMargin);
}
