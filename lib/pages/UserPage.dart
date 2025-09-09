import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_music_app/model/TenantUserModel.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';
import '../common/config.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../common/constant.dart';
import '../component/SelectDialogComponent.dart';
import '../model/TenantModel.dart';
import '../provider/UserInfoProvider.dart';
import '../router/index.dart';
import 'LoginPage.dart';
import '../model/UserInfoModel.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../service/serverMethod.dart';
import '../utils/common.dart';
import '../component/NavigatorTitleComponent.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  UserPageState createState() => UserPageState();
}

class UserPageState extends State<UserPage> {
  TextEditingController usernameController = TextEditingController(); // 姓名
  TextEditingController telController = TextEditingController(); // 电话
  TextEditingController emailController = TextEditingController(); // 邮箱
  TextEditingController signController = TextEditingController(); // 签名
  TextEditingController regionController = TextEditingController(); // 地区
  late UserInfoProvider userProvider;
  late ChatProvider chatProvider;
  bool hasChange = false;
  bool loading = false;
  List<TenantModel>tenantList = [];

  @override
  void initState() {
    getUserTenantList();
    super.initState();
  }

  ///@author: wuwenqiang
  ///@description: 修改用户信息弹窗
  /// @date: 2024-07-30 22:58
  useDialog(TextEditingController controller, String text, String name,String field, bool isRequire) {
    controller.text = text;
    showCustomDialog(
        context,
        Row(
          children: [
            Text(name),
            SizedBox(width: ThemeSize.smallMargin),
            Expanded(
                flex: 1,
                child: Card(
                    color: ThemeColors.disableColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ThemeSize.middleRadius),
                    ),
                    elevation: 0,
                    child: TextField(
                        onChanged: (value) {
                          hasChange = value != text;
                        },
                        textAlignVertical: TextAlignVertical.top,
                        controller: controller,
                        cursorColor: ThemeColors.grey,
                        //设置光标
                        decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.only(left: ThemeSize.miniMargin),
                          hintText: '请输入$name',
                          hintStyle: TextStyle(
                              fontSize: ThemeSize.smallFontSize,
                              color: ThemeColors.grey),
                          border: InputBorder.none,
                        ))))
          ],
        ),
        name, () {
      useSave(controller.text, name, field, isRequire);
    });
  }

  Future<void> useSave(dynamic value, String name, String field, bool isRequire) async {
    if (!hasChange || loading) return;
    loading = true;
    if (isRequire && value == "") {
      Fluttertoast.showToast(
          msg: "$name不能为空",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: ThemeSize.middleFontSize);
      loading = false;
    } else {
      await EasyLoading.show();
      Map myUserInfo = userProvider.userInfo.toMap();
      myUserInfo[field] = value;
      updateUserData(myUserInfo).then((value) async {
        hasChange = false;
        userProvider.setUserInfo(UserInfoModel.fromJson(myUserInfo));
        await EasyLoading.dismiss(animation: true);
        Navigator.pop(context);
        loading = false;
      }).catchError(() {
        loading = false;
      });
    }
  }

  ///@author: wuwenqiang
  ///@description: 生日
  /// @date: 2024-07-30 22:58
  useDatePicker() {
    int year = 0, month = 0, day = 0;
    List patter =
      userProvider.userInfo.birthday != null && userProvider.userInfo.birthday != ""
            ? userProvider.userInfo.birthday.split("-")
            : [];
    if (patter.length > 0) {
      year = int.parse(patter[0]);
      month = int.parse(patter[1]);
      day = int.parse(patter[2]);
    } else {
      DateTime dateTime = DateTime.now();
      year = dateTime.year - 20;
      month = dateTime.month;
      day = dateTime.day;
    }
    // showDatePicker(
    //   context: context,
    //   initialDate: DateTime(year, month, day),
    //   // 初始化选中日期
    //   firstDate: DateTime(1900, 6),
    //   // 开始日期
    //   lastDate: DateTime.now(),
    //   // 结束日期
    //   textDirection: TextDirection.ltr,
    //   // 文字方向
    //   helpText: "helpText",
    //   // 左上方提示
    //   cancelText: "取消",
    //   // 取消按钮文案
    //   confirmText: "确定",
    //   // 确认按钮文案
    //
    //   errorFormatText: "errorFormatText",
    //   // 格式错误提示
    //   errorInvalidText: "errorInvalidText",
    //   // 输入不在 first 与 last 之间日期提示
    //
    //   fieldLabelText: "fieldLabelText",
    //   // 输入框上方提示
    //   fieldHintText: "fieldHintText",
    //   // 输入框为空时内部提示
    //
    //   initialDatePickerMode: DatePickerMode.day,
    //   // 日期选择模式，默认为天数选择
    //   useRootNavigator: true, // 是否为根导航器
    // ).then((DateTime date) {
    //   if (date == null) return;
    //   String value =
    //       "${date.year.toString()}-${date.month.toString()}-${date.day.toString()}";
    //   hasChange = true;
    //   useSave(value, '出生年月','birthday' ,false);
    // });
  }

  getUserTenantList(){
    getUserTenantListService().then((res){
      if(res.data.isNotEmpty){
        setState(() {
          tenantList.add(TenantModel(id: '0', name: '私人空间', code: 'personal', status: 1, createdBy: 'system'));
          res.data.forEach((item){
            tenantList.add(TenantModel.fromJson(item));
          });
        });
      }
    });
  }
  onTabTenant(){
    BottomSelectionDialog.show(
        context:context,
        options:tenantList.map((item) {
          return item.name;
        }).toList(),
        onTap:(String value,int index) {
          getTenantUserService(tenantList[index].id).then((res){
            chatProvider.setTenantUser(TenantUserModel.fromJson(res.data ?? {}));
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserInfoProvider>(context, listen: true);
    chatProvider = Provider.of<ChatProvider>(context,listen: true);
    return Scaffold(
        backgroundColor: ThemeColors.colorBg,
        body: SafeArea(
            top: true,
            child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: <Widget>[
                    NavigatorTitleComponent(title: chatProvider.tenantUser.tenantName),
                    Expanded(
                        flex: 1,
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          padding: ThemeStyle.padding,
                          children: [
                            Container(
                              padding: ThemeStyle.padding,
                              decoration: ThemeStyle.boxDecoration,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                      decoration: ThemeStyle.bottomDecoration,
                                      padding: const EdgeInsets.only(
                                          bottom: ThemeSize.containerPadding),
                                      child: GestureDetector(
                                          onTap: () {
                                            // showSelectionDialog(["相机", "相册"],
                                            //     (String value) {
                                            //   getImage(value == "相机"
                                            //       ? getImage(ImageSource.camera)
                                            //       : ImageSource.gallery);
                                            // });
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Expanded(
                                                child: Text("头像"),
                                                flex: 1,
                                              ),
                                              ClipOval(
                                                child: Image.network(
                                                  //从全局的provider中获取用户信息
                                                  HOST +
                                                      userProvider.userInfo.avater,
                                                  height: ThemeSize.bigAvater,
                                                  width: ThemeSize.bigAvater,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              SizedBox(
                                                  width: ThemeSize.smallMargin),
                                              Image.asset(
                                                  "lib/assets/images/icon_arrow.png",
                                                  height: ThemeSize.miniIcon,
                                                  width: ThemeSize.miniIcon,
                                                  fit: BoxFit.cover),
                                            ],
                                          ))),
                                  Container(
                                    decoration: ThemeStyle.bottomDecoration,
                                    padding: ThemeStyle.columnPadding,
                                    child: GestureDetector(
                                      onTap: () {
                                        useDialog(
                                            usernameController,
                                            userProvider.userInfo.username,
                                            '昵称',
                                            'username',
                                            true);
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Expanded(
                                            child: Text("昵称"),
                                            flex: 1,
                                          ),
                                          Text(userProvider.userInfo.username),
                                          SizedBox(
                                              width: ThemeSize.smallMargin),
                                          Image.asset(
                                              "lib/assets/images/icon_arrow.png",
                                              height: ThemeSize.miniIcon,
                                              width: ThemeSize.miniIcon,
                                              fit: BoxFit.cover),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Container(
                                  //     decoration: ThemeStyle.bottomDecoration,
                                  //     padding: ThemeStyle.columnPadding,
                                  //     child: GestureDetector(
                                  //         onTap: () {
                                  //           useDialog(
                                  //               usernameController,
                                  //               userProvider.userInfo.telephone,
                                  //               '电话',
                                  //               'telephone',
                                  //               false);
                                  //         },
                                  //         child: Row(
                                  //           mainAxisAlignment:
                                  //               MainAxisAlignment.center,
                                  //           children: <Widget>[
                                  //             Expanded(
                                  //               child: Text("电话"),
                                  //               flex: 1,
                                  //             ),
                                  //             Text(userProvider.userInfo.telephone),
                                  //             SizedBox(
                                  //                 width: ThemeSize.smallMargin),
                                  //             Image.asset(
                                  //                 "lib/assets/images/icon_arrow.png",
                                  //                 height: ThemeSize.miniIcon,
                                  //                 width: ThemeSize.miniIcon,
                                  //                 fit: BoxFit.cover),
                                  //           ],
                                  //         ))),
                                  Container(
                                    decoration: ThemeStyle.bottomDecoration,
                                    padding: ThemeStyle.columnPadding,
                                    child: GestureDetector(
                                      onTap: () {
                                        useDialog(
                                            emailController,
                                            userProvider.userInfo.email ?? '',
                                            '邮箱',
                                            'email',
                                            false);
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          const Expanded(
                                            flex: 1,
                                            child: Text("邮箱"),
                                          ),
                                          Text(userProvider.userInfo.email),
                                          const SizedBox(
                                              width: ThemeSize.smallMargin),
                                          Image.asset(
                                              "lib/assets/images/icon_arrow.png",
                                              height: ThemeSize.miniIcon,
                                              width: ThemeSize.miniIcon,
                                              fit: BoxFit.cover),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                      decoration: ThemeStyle.bottomDecoration,
                                      padding: ThemeStyle.columnPadding,
                                      child: GestureDetector(
                                        onTap: () {
                                          BottomSelectionDialog.show(
                                              context:context,
                                              options:["男", "女"],
                                              onTap:(String value,int index) {
                                            hasChange = true;
                                            useSave(SexNameMap[value], 'sex',
                                                '性别', false);
                                          });
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Expanded(
                                              flex: 1,
                                              child: Text("性别"),
                                            ),
                                            Text(userProvider.userInfo.sex != null
                                                ? SexValueMap[
                                                    userProvider.userInfo.sex]!
                                                : ''),
                                            const SizedBox(
                                                width: ThemeSize.smallMargin),
                                            Image.asset(
                                                "lib/assets/images/icon_arrow.png",
                                                height: ThemeSize.miniIcon,
                                                width: ThemeSize.miniIcon,
                                                fit: BoxFit.cover),
                                          ],
                                        ),
                                      )),
                                  Container(
                                      decoration: ThemeStyle.bottomDecoration,
                                      padding: ThemeStyle.columnPadding,
                                      child: GestureDetector(
                                        onTap: () {
                                          useDialog(
                                              signController,
                                              userProvider.userInfo.sign ?? '',
                                              '签名',
                                              'sign',
                                              false);
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Expanded(
                                              child: Text("个性签名"),
                                              flex: 1,
                                            ),
                                            Text(userProvider.userInfo.sign ?? ""),
                                            SizedBox(
                                                width: ThemeSize.smallMargin),
                                            Image.asset(
                                                "lib/assets/images/icon_arrow.png",
                                                height: ThemeSize.miniIcon,
                                                width: ThemeSize.miniIcon,
                                                fit: BoxFit.cover),
                                          ],
                                        ),
                                      )),
                                  Container(
                                      padding: EdgeInsets.only(
                                          top: ThemeSize.columnPadding,
                                          bottom: ThemeSize.columnPadding -
                                              ThemeSize.containerPadding),
                                      child: GestureDetector(
                                        onTap: () {
                                          useDialog(
                                              regionController,
                                              userProvider.userInfo.region ?? '',
                                              '地区',
                                              'region',
                                              false);
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Expanded(
                                              flex: 1,
                                              child: Text("地区"),
                                            ),
                                            Text(
                                                userProvider.userInfo.region ?? ""),
                                            const SizedBox(
                                                width: ThemeSize.smallMargin),
                                            Image.asset(
                                                "lib/assets/images/icon_arrow.png",
                                                height: ThemeSize.miniIcon,
                                                width: ThemeSize.miniIcon,
                                                fit: BoxFit.cover),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            tenantList.isNotEmpty ?
                              GestureDetector(
                                onTap: onTabTenant,
                                child: Container(
                                    margin: const EdgeInsets.only(
                                        top: ThemeSize.containerPadding),
                                    decoration: BoxDecoration(
                                        color: ThemeColors.colorWhite,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(
                                                ThemeSize.superRadius)),
                                        border: Border.all(
                                            color: ThemeColors.borderColor)),
                                    width: double.infinity,
                                    height: ThemeSize.buttonHeight,
                                    child: const Center(child: Text("切换租户"))))
                            :const SizedBox(),
                            chatProvider.tenantUser.roleType > 0 ?
                            GestureDetector(
                                onTap: () {
                                  Routes.router.navigateTo(
                                      context, '/UpdatePasswordPage',
                                      replace: false);
                                },
                                child: Container(
                                    margin: const EdgeInsets.only(
                                        top: ThemeSize.containerPadding),
                                    decoration: BoxDecoration(
                                        color: ThemeColors.colorWhite,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(
                                                ThemeSize.superRadius)),
                                        border: Border.all(
                                            color: ThemeColors.borderColor)),
                                    width: double.infinity,
                                    height: ThemeSize.buttonHeight,
                                    child: const Center(child: Text("租户管理"))))
                            : const SizedBox(),
                            GestureDetector(
                                onTap: () {
                                  Routes.router.navigateTo(
                                      context, '/UpdatePasswordPage',
                                      replace: false);
                                },
                                child: Container(
                                    margin: const EdgeInsets.only(
                                        top: ThemeSize.containerPadding),
                                    decoration: BoxDecoration(
                                        color: ThemeColors.colorWhite,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(
                                                ThemeSize.superRadius)),
                                        border: Border.all(
                                            color: ThemeColors.borderColor)),
                                    width: double.infinity,
                                    height: ThemeSize.buttonHeight,
                                    child: const Center(child: Text("修改密码")))),
                            Container(
                              margin: EdgeInsets.only(
                                  top: ThemeSize.containerPadding),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.all(
                                    Radius.circular(ThemeSize.superRadius)),
                              ),
                              width: double.infinity,
                              child: MaterialButton(
                                onPressed: () {
                                  showCustomDialog(context, SizedBox(), '确认退出？',
                                          () {
                                        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => LoginPage()),
                                                (route) => route == null);
                                      });
                                },
                                child: const Text("退出登录",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            )
                          ],
                        ))
                  ],
                ))));
  }

  Future getImage(ImageSource source) async {
    // File image = await ImagePicker.pickImage(source: source);
    // List<int> imageBytes = await image.readAsBytes();
    // String base64Str = "data:image/png;base64," + base64Encode(imageBytes);
    // Map avaterMap = {"img": base64Str};
    // updateAvaterService(avaterMap).then((res) {
    //   userProvider.userInfo.avater = res.data;
    //   userProvider.setUserInfo(userProvider.userInfo);
    // });
  }
}
