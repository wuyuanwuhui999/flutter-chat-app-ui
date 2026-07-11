import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../common/constant.dart';

class LocalStorageUtils {
  static Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  static const String COMPANY_ID_STORAGE_KEY = 'COMPANY_ID_STORAGE_KEY';

  //从缓存中获取token
  static Future<String> getToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(TOKEN_STORAGE_KEY) ?? '';
    // 测试数据
    // return 'eyJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3MjE0MDMxMzMsInN1YiI6IntcImF2YXRlclwiOlwiL3N0YXRpYy91c2VyL2F2YXRlci_lkLTmgKjlkLTmgpQuanBnXCIsXCJiaXJ0aGRheVwiOlwiMTk5MC0xMC04XCIsXCJjcmVhdGVEYXRlXCI6MTU2NTYyNTYwMDAwMCxcImRpc2FibGVkXCI6MCxcImVtYWlsXCI6XCIyNzUwMTg3MjNAcXEuY29tXCIsXCJwZXJtaXNzaW9uXCI6MSxcInJvbGVcIjpcImFkbWluXCIsXCJzZXhcIjpcIjFcIixcInNpZ25cIjpcIuaXoOaAqO-8jOacieaClFwiLFwidGVsZXBob25lXCI6XCIxNTMwMjY4Njk0N1wiLFwidXBkYXRlRGF0ZVwiOjE3MTM3OTgwMzMwMDAsXCJ1c2VySWRcIjpcIuWQtOaAqOWQtOaClFwiLFwidXNlcm5hbWVcIjpcIuWQtOaAqOWQtOaClFwifSIsImV4cCI6MTcyMzk5NTEzM30.pB3xyg5-gnwzGerKDyeK2646l4FpHTwzpoRplKQg0zk';
  }

  //保存token
  static Future setToken(String token) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setString(TOKEN_STORAGE_KEY, token);
  }

  static Future<String>getTenantId() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(TENANT_ID_STORAGE_KEY) ?? '';
  }

  static Future<void>setTenantId(String tenantId) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setString(TENANT_ID_STORAGE_KEY,tenantId);
  }

   /// 从缓存中获取公司ID
  static Future<String> getCompanyId() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(COMPANY_ID_STORAGE_KEY) ?? '';
  }

  /// 保存公司ID到缓存（拼接userId）
  static Future<void> setCompanyId(String companyId, String userId) async {
    final SharedPreferences prefs = await _prefs;
    // 拼接userId和companyId，便于区分不同用户
    final key = '${COMPANY_ID_STORAGE_KEY}_$userId';
    prefs.setString(key, companyId);
    // 同时保存到通用key，方便快速获取
    prefs.setString(COMPANY_ID_STORAGE_KEY, companyId);
  }

  /// 根据userId获取公司ID
  static Future<String> getCompanyIdByUserId(String userId) async {
    final SharedPreferences prefs = await _prefs;
    final key = '${COMPANY_ID_STORAGE_KEY}_$userId';
    return prefs.getString(key) ?? '';
  }
}
