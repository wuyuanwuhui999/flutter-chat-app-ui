import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_music_app/model/TenantModel.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';
import '../common/config.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../common/constant.dart';
import '../component/CustomDialogComponent.dart';
import '../component/SelectDialogComponent.dart';
import '../model/TenantModel.dart';
import '../provider/UserInfoProvider.dart';
import '../router/index.dart';
import '../utils/LocalStorageUtils.dart';
import '../provider/TokenProvider.dart';
import '../utils/common.dart';
import 'LoginPage.dart';
import '../model/UserInfoModel.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../service/serverMethod.dart';
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

  @override
  void initState() {
    super.initState();
    // 初始化时加载租户列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTenantList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 加载租户列表
  /// @date: 2026-07-11
  void _loadTenantList() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final companyId = chatProvider.currentCompanyId;

    getTenantListService(companyId).then((res) {
      if (res.data.isNotEmpty) {
        final tenantList = res.data
            .map((item) => TenantModel.fromJson(item))
            .toList();

        // 保存到 ChatProvider
        chatProvider.setTenantList(tenantList);

        // 如果当前没有选中租户，从缓存获取或选择第一个
        if (!chatProvider.hasCurrentTenant) {
          LocalStorageUtils.getTenantId().then((cachedTenantId) {
            TenantModel? targetTenant;

            if (cachedTenantId.isNotEmpty) {
              targetTenant = chatProvider.getTenantById(cachedTenantId);
            }

            if (targetTenant == null && tenantList.isNotEmpty) {
              targetTenant = tenantList.first;
            }

            if (targetTenant != null) {
              chatProvider.setCurrentTenant(targetTenant);
              setState(() {});
            }
          });
        }
      }
    }).catchError((error) {
      debugPrint('加载租户列表失败: $error');
    });
  }

  /// @author: wuwenqiang
  /// @description: 修改用户信息弹窗
  /// @date: 2024-07-30 22:58
  void useDialog(TextEditingController controller, String text, String name, String field, bool isRequire) {
    controller.text = text;
    CustomDialogComponent(
      context: context,
      builder: (BuildContext context) {
        return Row(
          children: [
            Text(name),
            const SizedBox(width: ThemeSize.smallMargin),
            Expanded(
              flex: 1,
              child: Card(
                color: ThemeColors.gray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ThemeSize.middleRadius),
                ),
                elevation: 0,
                child: TextField(
                  onChanged: (value) {
                    hasChange = value != text;
                  },
                  textAlignVertical: TextAlignVertical.top,
                  controller: controller,
                  cursorColor: ThemeColors.gray,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: ThemeSize.miniMargin),
                    hintText: '请输入$name',
                    hintStyle: TextStyle(
                      fontSize: ThemeSize.smallFont,
                      color: ThemeColors.gray,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      name: "修改$name",
      okCallback: () {
        _saveUserInfo(controller.text, name, field, isRequire);
      },
    ).show();
  }

  /// @author: wuwenqiang
  /// @description: 保存用户信息
  /// @date: 2024-07-30 22:58
  Future<void> _saveUserInfo(dynamic value, String name, String field, bool isRequire) async {
    if (!hasChange || loading) return;
    loading = true;

    if (isRequire && value == "") {
      Fluttertoast.showToast(
        msg: "$name不能为空",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      loading = false;
      return;
    }

    await EasyLoading.show();
    Map<String, dynamic> myUserInfo = userProvider.userInfo.toMap();
    myUserInfo[field] = value;

    updateUserData(myUserInfo).then((value) async {
      hasChange = false;
      userProvider.setUserInfo(UserInfoModel.fromJson(myUserInfo));
      await EasyLoading.dismiss(animation: true);
      if (mounted) {
        Navigator.pop(context);
      }
      loading = false;
    }).catchError((error) {
      loading = false;
      EasyLoading.dismiss(animation: true);
      Fluttertoast.showToast(
        msg: "保存失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 显示租户切换弹窗
  /// @date: 2026-07-11
  void _showTenantSwitchDialog() {
    final tenantList = chatProvider.tenantList;

    if (tenantList.isEmpty) {
      Fluttertoast.showToast(
        msg: "暂无租户可切换",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // 构建选项列表，显示租户名称和角色
    final options = tenantList.map((item) {
      final isCurrent = item.id == chatProvider.currentTenantId;
      final roleText = item.roleText;
      return isCurrent ? '${item.name} ($roleText) ✓' : '${item.name} ($roleText)';
    }).toList();

    BottomSelectionDialog.show(
      context: context,
      options: options,
      onTap: (String value, int index) {
        final selectedTenant = tenantList[index];
        // 如果选择的是当前租户，不做任何操作
        if (selectedTenant.id == chatProvider.currentTenantId) {
          Fluttertoast.showToast(
            msg: "当前已是该租户",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
          return;
        }

        // 切换租户
        chatProvider.setCurrentTenant(selectedTenant);

        // 刷新页面
        setState(() {});

        Fluttertoast.showToast(
          msg: "已切换到: ${selectedTenant.name}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserInfoProvider>(context, listen: true);
    chatProvider = Provider.of<ChatProvider>(context, listen: true);

    final tenantList = chatProvider.tenantList;
    final currentTenantName = chatProvider.currentTenantName;
    final isAdmin = chatProvider.isCurrentTenantAdmin || chatProvider.isCurrentTenantOwner;

    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
        top: true,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: <Widget>[
              // 标题栏 - 显示当前租户名称
              NavigatorTitleComponent(
                title: currentTenantName,
              ),
              Expanded(
                flex: 1,
                child: ListView(
                  scrollDirection: Axis.vertical,
                  padding: ThemeStyle.padding,
                  children: [
                    // 个人信息卡片
                    Container(
                      padding: ThemeStyle.padding,
                      decoration: ThemeStyle.boxDecoration,
                      child: Column(
                        children: <Widget>[
                          // 头像
                          Container(
                            decoration: ThemeStyle.bottomDecoration,
                            padding: const EdgeInsets.only(
                              bottom: ThemeSize.middleGap,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                _showImagePickerDialog();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Expanded(
                                    child: Text("头像"),
                                    flex: 1,
                                  ),
                                  ClipOval(
                                    child: userProvider.userInfo.avater != null && userProvider.userInfo.avater!.isNotEmpty
                                        ? Image.network(
                                            getMusicCover(userProvider.userInfo.avater!),
                                            height: ThemeSize.bigAvater,
                                            width: ThemeSize.bigAvater,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            "lib/assets/images/default_avater.png",
                                            height: ThemeSize.bigAvater,
                                            width: ThemeSize.bigAvater,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  const SizedBox(width: ThemeSize.smallMargin),
                                  Image.asset(
                                    "lib/assets/images/icon_arrow.png",
                                    height: ThemeSize.miniIcon,
                                    width: ThemeSize.miniIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 昵称
                          Container(
                            decoration: ThemeStyle.bottomDecoration,
                            padding: ThemeStyle.middleGap,
                            child: GestureDetector(
                              onTap: () {
                                useDialog(
                                  usernameController,
                                  userProvider.userInfo.username,
                                  '昵称',
                                  'username',
                                  true,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Expanded(
                                    child: Text("昵称"),
                                    flex: 1,
                                  ),
                                  Text(userProvider.userInfo.username),
                                  const SizedBox(width: ThemeSize.smallMargin),
                                  Image.asset(
                                    "lib/assets/images/icon_arrow.png",
                                    height: ThemeSize.miniIcon,
                                    width: ThemeSize.miniIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 邮箱
                          Container(
                            decoration: ThemeStyle.bottomDecoration,
                            padding: ThemeStyle.middleGap,
                            child: GestureDetector(
                              onTap: () {
                                useDialog(
                                  emailController,
                                  userProvider.userInfo.email ?? '',
                                  '邮箱',
                                  'email',
                                  false,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Expanded(
                                    flex: 1,
                                    child: Text("邮箱"),
                                  ),
                                  Text(userProvider.userInfo.email ?? ''),
                                  const SizedBox(width: ThemeSize.smallMargin),
                                  Image.asset(
                                    "lib/assets/images/icon_arrow.png",
                                    height: ThemeSize.miniIcon,
                                    width: ThemeSize.miniIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 性别
                          Container(
                            decoration: ThemeStyle.bottomDecoration,
                            padding: ThemeStyle.middleGap,
                            child: GestureDetector(
                              onTap: () {
                                BottomSelectionDialog.show(
                                  context: context,
                                  options: const ["男", "女"],
                                  onTap: (String value, int index) {
                                    hasChange = true;
                                    _saveUserInfo(
                                      SexNameMap[value],
                                      '性别',
                                      'sex',
                                      false,
                                    );
                                  },
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Expanded(
                                    flex: 1,
                                    child: Text("性别"),
                                  ),
                                  Text(
                                    userProvider.userInfo.sex != null
                                        ? SexValueMap[userProvider.userInfo.sex] ?? ''
                                        : '',
                                  ),
                                  const SizedBox(width: ThemeSize.smallMargin),
                                  Image.asset(
                                    "lib/assets/images/icon_arrow.png",
                                    height: ThemeSize.miniIcon,
                                    width: ThemeSize.miniIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 个性签名
                          Container(
                            decoration: ThemeStyle.bottomDecoration,
                            padding: ThemeStyle.middleGap,
                            child: GestureDetector(
                              onTap: () {
                                useDialog(
                                  signController,
                                  userProvider.userInfo.sign ?? '',
                                  '签名',
                                  'sign',
                                  false,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Expanded(
                                    child: Text("个性签名"),
                                    flex: 1,
                                  ),
                                  Text(userProvider.userInfo.sign ?? ''),
                                  const SizedBox(width: ThemeSize.smallMargin),
                                  Image.asset(
                                    "lib/assets/images/icon_arrow.png",
                                    height: ThemeSize.miniIcon,
                                    width: ThemeSize.miniIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 地区
                          Container(
                            padding: EdgeInsets.only(
                              top: ThemeSize.middleGap,
                              bottom: ThemeSize.middleGap - ThemeSize.middleGap,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                useDialog(
                                  regionController,
                                  userProvider.userInfo.region ?? '',
                                  '地区',
                                  'region',
                                  false,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Expanded(
                                    flex: 1,
                                    child: Text("地区"),
                                  ),
                                  Text(userProvider.userInfo.region ?? ''),
                                  const SizedBox(width: ThemeSize.smallMargin),
                                  Image.asset(
                                    "lib/assets/images/icon_arrow.png",
                                    height: ThemeSize.miniIcon,
                                    width: ThemeSize.miniIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 切换租户按钮
                    if (tenantList.isNotEmpty)
                      GestureDetector(
                        onTap: _showTenantSwitchDialog,
                        child: Container(
                          margin: const EdgeInsets.only(
                            top: ThemeSize.middleGap,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(ThemeSize.superRadius),
                            ),
                            border: Border.all(
                              color: ThemeColors.gray,
                            ),
                          ),
                          width: double.infinity,
                          height: ThemeSize.btnHeight,
                          child: Center(
                            child: Text(
                              '切换租户 (当前: $currentTenantName)',
                              style: const TextStyle(
                                color: ThemeColors.mainTitle,
                                fontSize: ThemeSize.normalFont,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 租户管理按钮（仅管理员可见）
                    if (isAdmin)
                      GestureDetector(
                        onTap: () {
                          Routes.router.navigateTo(
                            context,
                            '/TenantManagePage',
                            replace: false,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            top: ThemeSize.middleGap,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(ThemeSize.superRadius),
                            ),
                            border: Border.all(
                              color: ThemeColors.gray,
                            ),
                          ),
                          width: double.infinity,
                          height: ThemeSize.btnHeight,
                          child: const Center(
                            child: Text(
                              "租户管理",
                              style: TextStyle(
                                color: ThemeColors.mainTitle,
                                fontSize: ThemeSize.normalFont,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 修改密码
                    GestureDetector(
                      onTap: () {
                        Routes.router.navigateTo(
                          context,
                          '/UpdatePasswordPage',
                          replace: false,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: ThemeSize.middleGap,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.white,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(ThemeSize.superRadius),
                          ),
                          border: Border.all(
                            color: ThemeColors.gray,
                          ),
                        ),
                        width: double.infinity,
                        height: ThemeSize.btnHeight,
                        child: const Center(
                          child: Text(
                            "修改密码",
                            style: TextStyle(
                              color: ThemeColors.mainTitle,
                              fontSize: ThemeSize.normalFont,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 退出登录
                    Container(
                      margin: const EdgeInsets.only(
                        top: ThemeSize.middleGap,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColors.warn,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(ThemeSize.superRadius),
                        ),
                      ),
                      width: double.infinity,
                      child: MaterialButton(
                        onPressed: _showLogoutDialog,
                        child: const Text(
                          "退出登录",
                          style: TextStyle(
                            color: ThemeColors.white,
                            fontSize: ThemeSize.normalFont,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 显示图片选择对话框
  /// @date: 2024-07-30 22:58
  void _showImagePickerDialog() {
    BottomSelectionDialog.show(
      context: context,
      options: const ["相机", "相册"],
      onTap: (String value, int index) {
        final source = value == "相机" ? ImageSource.camera : ImageSource.gallery;
        _getImage(source);
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 获取图片并上传头像
  /// @date: 2024-07-30 22:58
  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image == null) return;

      // 显示加载中
      await EasyLoading.show(status: '上传中...');

      // TODO: 实现头像上传功能
      // 这里需要调用上传头像的接口
      // 目前注释掉，待实现
      /*
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final base64Str = "data:image/png;base64," + base64Encode(bytes);

      updateAvaterService({"img": base64Str}).then((res) {
        if (res.status == SUCCESS) {
          userProvider.userInfo.avater = res.data;
          userProvider.setUserInfo(userProvider.userInfo);
          Fluttertoast.showToast(msg: "头像更新成功");
        }
      }).finally(() {
        EasyLoading.dismiss();
      });
      */

      await EasyLoading.dismiss();
      Fluttertoast.showToast(
        msg: "头像上传功能开发中",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    } catch (e) {
      await EasyLoading.dismiss();
      Fluttertoast.showToast(
        msg: "选择图片失败: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  /// @author: wuwenqiang
  /// @description: 显示退出登录确认对话框
  /// @date: 2024-07-30 22:58
  void _showLogoutDialog() {
    CustomDialogComponent(
      context: context,
      builder: (BuildContext context) {
        return const SizedBox();
      },
      name: '确认退出？',
      okCallback: () {
        _logout();
      },
    ).show();
  }

  /// @author: wuwenqiang
  /// @description: 退出登录
  /// @date: 2024-07-30 22:58
  Future<void> _logout() async {
    // 清除缓存
    await LocalStorageUtils.setToken('');
    await LocalStorageUtils.setTenantId('');

    // 清除 Provider 数据
    final tokenProvider = Provider.of<TokenProvider>(context, listen: false);
    tokenProvider.setToken('');

    // 跳转到登录页
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
}