import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/LocalStorageUtils.dart';
import '../common/constant.dart';
import '../service/serverMethod.dart';
enum  LoopModeEnum {
  ORDER,// 顺序播放
  RANDOM,// 随机播放
  REPEAT// 单曲循环
}

class ChatProvider with ChangeNotifier {
  ChatProvider();
  late String _version;
  late String _device;
  final String _platform = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

  void setVersion(String version){
    _version = version;
  }

  void setDevice(String device){
    _device = device;
  }

  get version => _version;

  get device => _device;
}
