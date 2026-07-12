import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/model/CompanyModel.dart';
import 'package:flutter_chat_app/model/DirectoryModel.dart';
import 'package:flutter_chat_app/model/TenantModel.dart';
import '../utils/LocalStorageUtils.dart';
import '../common/constant.dart';

class ChatProvider with ChangeNotifier {
  late String _version;
  late String _device;
  final String _platform =
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  List<DirectoryModel> _directoryList = [];

  // ✅ 租户列表
  List<TenantModel> _tenantList = [];

  // ✅ 当前选中的租户
  TenantModel? _currentTenant;

  // 当前选中的公司对象
  CompanyModel? _currentCompany;

  void setVersion(String version) {
    _version = version;
  }

  void setDevice(String device) {
    _device = device;
  }

  /// @author: wuwenqiang
  /// @description: 设置租户列表
  /// @date: 2026-07-11
  void setTenantList(List<TenantModel> list) {
    _tenantList = list;
    notifyListeners();
  }

  /// @author: wuwenqiang
  /// @description: 设置当前租户并缓存到本地
  /// @date: 2026-07-11
  void setCurrentTenant(TenantModel tenant) {
    _currentTenant = tenant;
    // 缓存租户ID到本地
    LocalStorageUtils.setTenantId(tenant.id);
    notifyListeners();
  }

  /// @author: wuwenqiang
  /// @description: 根据租户ID查找租户
  /// @date: 2026-07-11
  TenantModel? getTenantById(String tenantId) {
    try {
      return _tenantList.firstWhere((t) => t.id == tenantId);
    } catch (e) {
      return null;
    }
  }

  /// @author: wuwenqiang
  /// @description: 获取用户在指定租户中的角色
  /// @date: 2026-07-11
  int getRoleInTenant(String tenantId) {
    final tenant = getTenantById(tenantId);
    return tenant?.role ?? 0;
  }

  /// @author: wuwenqiang
  /// @description: 切换租户
  /// @date: 2026-07-11
  void switchTenant(String tenantId) {
    final tenant = getTenantById(tenantId);
    if (tenant != null) {
      _currentTenant = tenant;
      LocalStorageUtils.setTenantId(tenantId);
      notifyListeners();
    }
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

  // ✅ Getters
  get version => _version;
  get device => _device;

  // ✅ 租户相关 getters
  List<TenantModel> get tenantList => _tenantList;
  TenantModel? get currentTenant => _currentTenant;
  String get currentTenantId => _currentTenant?.id ?? '';
  String get currentTenantName => _currentTenant?.name ?? '默认空间';
  int get currentTenantRole => _currentTenant?.role ?? 0;
  bool get isCurrentTenantAdmin => _currentTenant?.isAdmin ?? false;
  bool get isCurrentTenantOwner => _currentTenant?.isOwner ?? false;
  bool get hasCurrentTenant => _currentTenant != null;

  get directoryList => _directoryList;

  // 公司相关 getters
  CompanyModel? get currentCompany => _currentCompany;
  String get currentCompanyId => _currentCompany?.id ?? '';
  String get currentCompanyRole => _currentCompany?.role?.toString() ?? '';
  int get currentCompanyRoleInt => _currentCompany?.role ?? 0;
}