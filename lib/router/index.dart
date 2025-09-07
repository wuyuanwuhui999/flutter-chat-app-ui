import 'dart:convert';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import '../pages/ChatPage.dart';
import '../pages/LoginPage.dart';
import '../pages/ForgetPasswordPage.dart';
import '../pages/NotFoundPage.dart';
import '../pages/ResetPasswordPage.dart';
import '../pages/UpdatePasswordPage.dart';
import '../pages/UserPage.dart';
import '../pages/RegisterPage.dart';
class Routes {
  static final FluroRouter router = FluroRouter();
  static void initRoutes() {
    /// 指定路由跳转错误返回页
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
          debugPrint('未找到目标页');
          return const NotFoundPage();
        });
    router.define('/LoginPage', handler: Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return const LoginPage();
    }));
    router.define('/ForgetPasswordPage', handler: Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return ForgetPasswordPage();
    }));
    router.define('/ResetPasswordPage', handler: Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return ResetPasswordPage(email: json.decode(params['email']!.first));
    }));
    router.define('/UpdatePasswordPage', handler: Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return UpdatePasswordPage();
    }));
    router.define('/UserPage', handler: Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return const UserPage();
    }));
    router.define('/RegisterPage', handler: Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return const RegisterPage();
    }));
    router.define('/ChatPage', handler: Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return const ChatPage();
    }));
  }
}