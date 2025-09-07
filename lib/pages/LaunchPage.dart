import 'dart:io';
import 'package:flutter/material.dart';
import '../provider/ChatProvider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../router/index.dart';
import '../service/serverMethod.dart';
import '../utils/HttpUtil.dart';
import '../provider/UserInfoProvider.dart';
import 'package:provider/provider.dart';
import '../utils/LocalStorageUtils.dart';
import '../model/UserInfoModel.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  LaunchPageState createState() => LaunchPageState();
}

class LaunchPageState extends State<LaunchPage> {
  late UserInfoProvider userInfoprovider;
  late ChatProvider chatProvider;
  late String version;

  @override
  void initState() {
    userInfoprovider =  Provider.of<UserInfoProvider>(context,listen: false);
    chatProvider = Provider.of<ChatProvider>(context,listen: false);

    LocalStorageUtils.getToken().then((res){
      Future.delayed(const Duration(seconds: 1), () {
        // 这里是你想要延时执行的代码
        HttpUtil.getInstance().setToken(res);
        if(res != ""){// 已经登录
          getUserDataService().then((data){
            if(data.token != null){
              String token = data.token!;
              LocalStorageUtils.setToken(token);
              HttpUtil.getInstance().setToken(token);
              userInfoprovider.setUserInfo(UserInfoModel.fromJson(data.data));
            }
            Routes.router.navigateTo(context, '/MusicIndexPage',replace: true);
          }).catchError((err){
            Routes.router.navigateTo(context, '/LoginPage',replace: true);
          });
        }else{// 没有登录
          Routes.router.navigateTo(context, '/LoginPage',replace: true);
        }
      });
    });
     PackageInfo.fromPlatform().then((value){
       chatProvider.setVersion(value.version);
    });
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      deviceInfo.androidInfo.then((value){
        chatProvider.setDevice(value.model);
      });
    } else if (Platform.isIOS) {
      deviceInfo.iosInfo.then((value){
        chatProvider.setDevice(value.model);
      });
    }else{
      chatProvider.setDevice('Unknown');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child:Center(child: Text('欢迎使用')),
          ),
        ));
  }
}
