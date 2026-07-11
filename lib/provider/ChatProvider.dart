// lib/provider/ChatProvider.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_music_app/model/CompanyModel.dart'; // 新增导入
import 'package:flutter_music_app/model/DirectoryModel.dart';
import 'package:flutter_music_app/model/TenantUserModel.dart';
import '../model/TenantModel.dart';
import '../utils/LocalStorageUtils.dart';
import '../common/constant.dart';
import '../service/serverMethod.dart';

class ChatProvider with ChangeNotifier {
  late String _version;
  late String _device;
  final String _platform =
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  List<DirectoryModel> _directoryList = [];
  TenantUserModel _tenantUser = TenantUserModel(
    id: "",
    tenantId: 'personal',
    tenantName: '私人空间',
    userId: '',
    role: 0,
    disabled: 0,
    username: '',
  );
  
  // 新增：当前选中的公司对象
  CompanyModel? _currentCompany;

  void setVersion(String version) {
    _version = version;
  }

  void setDevice(String device) {
    _device = device;
  }

  void setTenantUser(TenantUserModel tenantUser) {
    LocalStorageUtils.setTenantId(tenantUser.tenantId);
    _tenantUser = tenantUser;
    notifyListeners(); // 更新UI
  }

  // 添加目录的方法
  void addDirectory(DirectoryModel directory) {
    _directoryList.add(directory);
    notifyListeners();
  }

  // 获取目录列表的方法
  void setDirectoryList(List<DirectoryModel> list) {
    _directoryList = list;
    notifyListeners();
  }

  // 新增：设置当前公司
  void setCurrentCompany(CompanyModel company) {
    _currentCompany = company;
    notifyListeners();
  }

  // 新增：清除当前公司
  void clearCurrentCompany() {
    _currentCompany = null;
    notifyListeners();
  }

  // Getters
  get version => _version;
  get device => _device;
  get tenantUser => _tenantUser;
  get directoryList => _directoryList;
  
  // 新增Getter
  CompanyModel? get currentCompany => _currentCompany;
  String get currentCompanyId => _currentCompany?.id ?? '';
  
  /// 获取当前公司角色（返回字符串）
  String get currentCompanyRole => _currentCompany?.role?.toString() ?? '';
  
  /// 获取当前公司角色（返回整型）
  int get currentCompanyRoleInt => _currentCompany?.role ?? 0;
}