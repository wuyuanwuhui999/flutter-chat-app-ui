import 'dart:async';
import 'package:dio/dio.dart';
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
Future<ResponseModel<List<dynamic>>> getMyDocListService() async {
  try {
    Response response =
    await dio.get(servicePath['getDocList']!);
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

