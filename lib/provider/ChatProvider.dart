import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_music_app/model/TenantUserModel.dart';
import '../model/TenantModel.dart';
import '../utils/LocalStorageUtils.dart';
import '../common/constant.dart';
import '../service/serverMethod.dart';
enum  LoopModeEnum {
  ORDER,// 顺序播放
  RANDOM,// 随机播放
  REPEAT// 单曲循环
}

class ChatProvider with ChangeNotifier {
  late String _version;
  late String _device;
  final String _platform = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

  TenantUserModel _tenantUser = TenantUserModel(id: "", tenantId: 'personal', tenantName: '私人空间', userId: '', roleType: 0, disabled: 0, username: '',);

  void setVersion(String version){
    _version = version;
  }

  void setDevice(String device){
    _device = device;
  }

  void setTenantUser(TenantUserModel tenantUser){
    LocalStorageUtils.setTenantId(tenantUser.tenantId);
    _tenantUser = tenantUser;
    notifyListeners(); // 更新UI
  }

  get version => _version;

  get device => _device;

  get tenantUser => _tenantUser;
}
