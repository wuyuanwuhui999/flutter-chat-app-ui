import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_music_app/model/DirectoryModel.dart';
import '../common/config.dart';
import '../model/FavoriteDirectoryModel.dart';
import '../api/api.dart';
import '../utils/HttpUtil.dart';
import '../utils/LocalStorageUtils.dart';
import '../utils/crypto.dart';

//获取用户数据
Future<ResponseModel<dynamic>> getUserDataService() async {
  try {
    String token = await LocalStorageUtils.getToken(); //从缓存中获取
    HttpUtil.getInstance().setToken(token);
    Response response = await dio.get(servicePath["getUserData"]!);
    HttpUtil.getInstance().setToken(response.data['token']);
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
    // return ResponseModel.fromJson(null);
  }
}

//登录
Future<ResponseModel<dynamic>> loginService(
    String userAccount, String password) async {
  try {
    Response response = await dio.post(servicePath['login']!, data: {'userAccount':userAccount,'password':generateMd5(password)});
    HttpUtil.getInstance().setToken(response.data['token']);
    print(servicePath['login']!);
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
    return ResponseModel.fromJson(null);
  }
}

///@author: wuwenqiang
///@description: 更新用户信息
/// @date: 2021-04-20 23:57
Future<ResponseModel<int>> updateUserData(Map map) async {
  try {
    Response response = await dio.put(servicePath['updateUser']!, data: map);
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    return ResponseModel.fromJson(null);
  }
}

///@author: wuwenqiang
///@description: 更新用户信息
/// @date: 2025-04-05 19:59
Future<ResponseModel<int>>sendEmailVertifyCodeService(String email) async {
  try {
    Response response = await dio.post(servicePath['sendEmailVertifyCode']!,data:{'email':email});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    return ResponseModel.fromJson(null);
  }
}

Future<ResponseModel<dynamic>>resetPasswordService(String email,String password,String code) async {
  password = generateMd5(password);
  try {
    Response response = await dio.post(servicePath['resetPassword']!,data:{'email':email,'code':code,'password':password});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    return ResponseModel.fromJson(null);
  }
}

///@author: wuwenqiang
///@description: 更新密码
/// @date: 2021-04-20 23:57
Future<ResponseModel<int>> updatePasswordService(String oldPassword,String newPassword) async {
  try {
    oldPassword = generateMd5(oldPassword);
    newPassword = generateMd5(newPassword);
    Response response = await dio.put(servicePath['updatePassword']!, data: {"oldPassword":oldPassword,"newPassword":newPassword});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    return ResponseModel.fromJson(null);
  }
}

///@author: wuwenqiang
///@description: 更新密码
/// @date: 2021-04-20 23:57
Future<ResponseModel<dynamic>> loginByEmailService(String email,String code) async {
  try {
    Response response = await dio.post(servicePath['loginByEmail']!, data: {"email":email,"code":code});
    HttpUtil.getInstance().setToken(response.data['token']);
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    return ResponseModel.fromJson(null);
  }
}

///@author: wuwenqiang
///@description: 获取模型列表
/// @date: 2025-06-08 20:21
Future<ResponseModel<List<dynamic>>> getModelListService() async {
  try {
    Response response =
    await dio.get(servicePath['getModelList']!,);
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 获取历史对话
/// @date: 2025-06-09 19:39
Future<ResponseModel<List<dynamic>>> getChatHistoryService(int pageNum,int pageSize) async {
  try {
    Response response =
    await dio.get(servicePath['getChatHistory']!,queryParameters:{"pageNum":pageNum,"pageSize":pageSize});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 获取文档列表
/// @date: 2025-06-09 19:39
Future<ResponseModel<List<dynamic>>> getMyDocListService(String tenantId) async {
  try {
    Response response =
    await dio.get(servicePath['getDocList']!,queryParameters: {"tenantId":tenantId});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

  ///@author: wuwenqiang
  ///@description: 获取用户租户列表
  /// @date: 2025-06-09 19:39
  Future<ResponseModel<List<dynamic>>> getUserTenantListService() async {
    try {
      Response response =
      await dio.get(servicePath['getUserTenantList']!);
      return ResponseModel.fromJson(response.data);
    } catch (e) {
      print('ERROR:======>${e}');
      throw Error();
    }
}

///@author: wuwenqiang
///@description: 获取文档列表
/// @date: 2025-06-09 19:39
Future<ResponseModel<void>> deleteMyDocumentService(String docId) async {
  try {
    Response response =
    await dio.delete("${servicePath['getDocList']}$docId");
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 获取文档列表
/// @date: 2025-06-09 19:39
Future<ResponseModel<List<dynamic>>> getDirectoryListService(String tenantId) async {
  try {
    Response response =
    await dio.get(servicePath['getDirectoryList']!,queryParameters:{"tenantId":tenantId});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 获取当前租户的用户信息
/// @date: 2025-06-09 19:39
Future<ResponseModel<dynamic>> getTenantUserService(String tenantId) async {
  try {
    Response response =
    await dio.get(servicePath['getTenantUser']!,queryParameters:{"tenantId":tenantId});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 获取当前租户的用户列表
/// @date: 2025-06-09 19:39
Future<ResponseModel<List<dynamic>>> getTenantUserListService(String tenantId,int pageNum,int pageSize) async {
  try {
    Response response =
    await dio.get(servicePath['getTenantUserList']!,queryParameters:{"pageNum":pageNum,"pageSize":pageSize,"tenantId":tenantId});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 设置租户为管理员
/// @date: 2025-09-12 09:36
Future<ResponseModel<int>> addAdminService(String tenantId,String userId) async {
  try {
    Response response =
    await dio.put("${servicePath['addAdmin']}/${tenantId}/${userId}");
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 取消租户为管理员
/// @date: 2025-09-12 09:36
Future<ResponseModel<int>> cancelAdminService(String tenantId,String userId) async {
  try {
    Response response =
    await dio.put("${servicePath['cancelAdmin']}/${tenantId}/${userId}");
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 取消租户为管理员
/// @date: 2025-09-12 09:36
Future<ResponseModel<List<dynamic>>> searchUsersService(String tenantId,String keyword) async {
  try {
    Response response =
    await dio.get(servicePath['searchUsers']!,queryParameters: {"tenantId":tenantId,"keyword":keyword});
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 添加租户为用户
/// @date: 2025-09-12 17:22
Future<ResponseModel<dynamic>> addTenantUserService(String tenantId,String userId) async {
  try {
    Response response =
    await dio.post("${servicePath['addTenantUser']}/${tenantId}/${userId}");
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 添加租户为用户
/// @date: 2025-09-12 17:22
Future<ResponseModel<int>> deleteTenantUserService(String tenantId,String userId) async {
  try {
    Response response =
    await dio.delete("${servicePath['deleteTenantUser']}/${tenantId}/${userId}");
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}

///@author: wuwenqiang
///@description: 添加租户为用户
/// @date: 2025-09-12 17:22
Future<ResponseModel<dynamic>> createDirService(DirectoryModel directoryMode) async {
  try {
    Response response =
    await dio.post(servicePath['createDir']!,data:directoryMode.toJson());
    return ResponseModel.fromJson(response.data);
  } catch (e) {
    print('ERROR:======>${e}');
    throw Error();
  }
}
