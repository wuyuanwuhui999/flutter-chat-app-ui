import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../router/index.dart';
import '../service/serverMethod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/crypto.dart';
import '../provider/UserInfoProvider.dart';
import 'package:provider/provider.dart';
import '../utils/LocalStorageUtils.dart';
import '../model/UserInfoModel.dart';
import '../theme/ThemeStyle.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeColors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  int tabIndex = 0;
  late UserInfoProvider userInfoProvider;

  @override
  Widget build(BuildContext context) {
    userInfoProvider = Provider.of<UserInfoProvider>(context,listen: true);
    String userAccount = userInfoProvider.userInfo?.userAccount ?? "";
    String email = "";
    String code = "";
    TextEditingController userController = TextEditingController(text: userAccount);
    TextEditingController pwdController = TextEditingController(text: "");
    TextEditingController emailController = TextEditingController(text: "");
    TextEditingController codeController = TextEditingController(text: "");

    String password = "123456";
    return Scaffold(
        backgroundColor: ThemeColors.background,
        body: SafeArea(
          child: Container(
            padding: ThemeStyle.padding,
            margin: ThemeStyle.padding,
            decoration: ThemeStyle.boxDecoration,
            child: Column(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Center(
                        child: Image.asset(
                          "lib/assets/images/icon_ai.png",
                          width: ThemeSize.bigIcon,
                          height: ThemeSize.bigIcon,
                        )),
                    const SizedBox(
                      height: ThemeSize.middleGap * 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: InkWell(
                                onTap: () {
                                  setState(() {
                                    tabIndex = 0;
                                  });
                                },
                                child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              width: ThemeSize.borderSize,
                                              //宽度
                                              color: tabIndex == 0
                                                  ? ThemeColors.primary
                                                  : Colors.transparent, //边框颜色
                                            ),
                                          )),
                                      child: const Text("账号密码登录"),
                                    )))),
                        Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  tabIndex = 1;
                                });
                              },
                              child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            width: ThemeSize.borderSize, //宽度
                                            color: tabIndex == 1
                                                ? ThemeColors.primary
                                                : Colors.transparent, //边框颜色
                                          ),
                                        )),
                                    child: const Text("邮箱验证码登录"),
                                  )),
                            )),
                      ],
                    ),
                    SizedBox(
                      height: ThemeSize.middleGap,
                    ),
                    tabIndex == 0
                        ? Column(
                      children: [
                        Container(
                            margin: ThemeStyle.margin,
                            padding: EdgeInsets.only(
                                left: ThemeSize.middleGap),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(
                                        ThemeSize.superRadius)),
                                border: Border.all(
                                    color: ThemeColors.gray)),
                            child: TextField(
                                onChanged: (value) {
                                  if (value != "") {
                                    userAccount = value;
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: "请输入用户名",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor:
                                        ThemeColors.gray,
                                        fontSize:
                                        ThemeSize.middleFont);
                                  }
                                },
                                controller: userController,
                                cursorColor: ThemeColors.gray, //设置光标
                                decoration: InputDecoration(
                                  hintText: "请输入用户名",
                                  icon: Image.asset(
                                      "lib/assets/images/icon_user.png",
                                      width: ThemeSize.smallIcon,
                                      height: ThemeSize.smallIcon),
                                  hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: ThemeColors.gray),
                                  contentPadding:
                                  EdgeInsets.only(left: 0.0),
                                  border: InputBorder.none,
                                ))),
                        Container(
                            padding: EdgeInsets.only(
                                left: ThemeSize.middleGap),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(
                                        ThemeSize.superRadius)),
                                border: Border.all(
                                    color: ThemeColors.gray)),
                            child: TextField(
                                onChanged: (value) {
                                  if (value != "") {
                                    password = value;
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: "请输入密码",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor:
                                        ThemeColors.gray,
                                        fontSize:
                                        ThemeSize.middleFont);
                                  }
                                },
                                controller: pwdController,
                                obscureText: true,
                                cursorColor: ThemeColors.gray,
                                //设置光标
                                decoration: InputDecoration(
                                  icon: Image.asset(
                                      "lib/assets/images/icon_password.png",
                                      width: ThemeSize.smallIcon,
                                      height: ThemeSize.smallIcon),
                                  hintText: "请输入密码",
                                  hintStyle: TextStyle(
                                      fontSize: ThemeSize.smallFont,
                                      color: ThemeColors.gray),
                                  border: InputBorder.none,
                                )))
                      ],
                    )
                        : Column(children: [
                      Container(
                          margin: ThemeStyle.margin,
                          padding: EdgeInsets.only(
                              left: ThemeSize.middleGap),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(
                                      ThemeSize.superRadius)),
                              border: Border.all(
                                  color: ThemeColors.gray)),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: TextField(
                                      onChanged: (value) {
                                        if (value != "") {
                                          email = value;
                                        } else {
                                          Fluttertoast.showToast(
                                              msg: "请输入邮箱",
                                              toastLength:
                                              Toast.LENGTH_SHORT,
                                              gravity:
                                              ToastGravity.CENTER,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor:
                                              ThemeColors
                                                  .gray,
                                              fontSize: ThemeSize
                                                  .middleFont);
                                        }
                                      },
                                      controller: emailController,
                                      cursorColor:
                                      ThemeColors.gray, //设置光标
                                      decoration: InputDecoration(
                                        hintText: "请输入邮箱",
                                        icon: Image.asset(
                                            "lib/assets/images/icon_user.png",
                                            width: ThemeSize.smallIcon,
                                            height:
                                            ThemeSize.smallIcon),
                                        hintStyle: TextStyle(
                                            fontSize: 14,
                                            color: ThemeColors.gray),
                                        contentPadding:
                                        EdgeInsets.only(left: 0.0),
                                        border: InputBorder.none,
                                      ))),
                              InkWell(
                                onTap: () async {
                                  await EasyLoading.show();
                                  sendEmailVertifyCodeService(email).then((res){
                                    Fluttertoast.showToast(
                                        msg: res.msg??"",
                                        toastLength:
                                        Toast.LENGTH_SHORT,
                                        gravity:
                                        ToastGravity.CENTER,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor:
                                        ThemeColors
                                            .gray,
                                        fontSize: ThemeSize
                                            .middleFont);
                                    EasyLoading.dismiss(animation: true);
                                  });
                                },
                                child: Image.asset(
                                    "lib/assets/images/icon_send.png",
                                    width: ThemeSize.smallIcon,
                                    height: ThemeSize.smallIcon),
                              ),
                              SizedBox(width: ThemeSize.middleGap)
                            ],
                          )),
                      Container(
                          margin: ThemeStyle.margin,
                          padding: EdgeInsets.only(
                              left: ThemeSize.middleGap),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(
                                      ThemeSize.superRadius)),
                              border: Border.all(
                                  color: ThemeColors.gray)),
                          child: TextField(
                              onChanged: (value) {
                                if (value != "") {
                                  code = value;
                                } else {
                                  Fluttertoast.showToast(
                                      msg: "请输入验证码",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor:
                                      ThemeColors.gray,
                                      fontSize:
                                      ThemeSize.middleFont);
                                }
                              },
                              controller: codeController,
                              cursorColor: ThemeColors.gray, //设置光标
                              decoration: InputDecoration(
                                hintText: "请输入验证码",
                                icon: Image.asset(
                                    "lib/assets/images/icon_code.png",
                                    width: ThemeSize.smallIcon,
                                    height: ThemeSize.smallIcon),
                                hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: ThemeColors.gray),
                                border: InputBorder.none,
                              ))),
                    ]),
                    SizedBox(height: ThemeSize.middleGap),
                  ],
                ),
                Column(
                  children: <Widget>[
                    InkWell(
                      onTap: () async {
                        if (tabIndex == 0) {
                          loginService(userAccount, password).then((res) async {
                            if (res.data != null) {
                              await LocalStorageUtils.setToken(res.token!);
                              await Fluttertoast.showToast(
                                  msg: "登录成功",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                  fontSize: ThemeSize.middleFont);
                              print(res.data);
                              UserInfoModel userModel = UserInfoModel.fromJson(res.data);
                              print(userModel);
                              print("111");
                              userInfoProvider.setUserInfo(userModel);
                              Routes.router.navigateTo(
                                  context, '/ChatPage',
                                  replace: true);

                            } else {
                              Fluttertoast.showToast(
                                  msg: "登录失败，账号或密码错误",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: ThemeSize.middleFont);
                            }
                          }).catchError((){
                            Fluttertoast.showToast(
                                msg: "登录失败，账号或密码错误",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: ThemeSize.middleFont);
                          });
                        } else if (email.trim() == "") {
                          Fluttertoast.showToast(
                              msg: "请输入邮箱",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: ThemeColors.gray,
                              fontSize: ThemeSize.middleFont);
                        } else if (code.trim() == "") {
                          Fluttertoast.showToast(
                              msg: "请输入验证码",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: ThemeColors.gray,
                              fontSize: ThemeSize.middleFont);
                        }else{
                          await EasyLoading.show();
                          loginByEmailService(emailController.text,codeController.text).then((res) async {
                            if (res.data != null) {
                              await LocalStorageUtils.setToken(res.token!);
                              await Fluttertoast.showToast(
                                  msg: "登录成功",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                  fontSize: ThemeSize.middleFont);
                              EasyLoading.dismiss();
                              userInfoProvider.setUserInfo(
                                  UserInfoModel.fromJson(res.data));
                              Routes.router.navigateTo(
                                  context, '/ChatPage',
                                  replace: true);
                            } else {
                              Fluttertoast.showToast(
                                  msg: "登录失败，账号或密码错误",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: ThemeSize.middleFont);
                            }
                          });
                        }
                      },
                      child: Container(
                        height: ThemeSize.btnHeight,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(
                              Radius.circular(ThemeSize.superRadius)),
                        ),
                        width: double.infinity,
                        child: const Center(
                            child: Text("登录",
                                style:
                                    TextStyle(color: ThemeColors.white))),
                      ),
                    ),
                    const SizedBox(height: ThemeSize.middleGap),
                    InkWell(
                        onTap: () {
                          Routes.router.navigateTo(context, '/RegisterPage',
                              replace: false);
                        },
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(ThemeSize.superRadius)),
                                border:
                                    Border.all(color: ThemeColors.gray)),
                            width: double.infinity,
                            height: ThemeSize.btnHeight,
                            child: const Center(child: Text("注册")))),
                    SizedBox(height: ThemeSize.middleGap),
                    InkWell(
                        onTap: () {
                          Routes.router.navigateTo(
                              context, '/ForgetPasswordPage',
                              replace: false);
                        },
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(ThemeSize.superRadius)),
                                border:
                                    Border.all(color: ThemeColors.gray)),
                            width: double.infinity,
                            height: ThemeSize.btnHeight,
                            child: const Center(child: Text("忘记密码"))))
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
