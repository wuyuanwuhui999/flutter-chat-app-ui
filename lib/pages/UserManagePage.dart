import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_chat_app/component/AvaterComponent.dart';
import 'package:flutter_chat_app/model/UserInfoModel.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../common/constant.dart';
import '../component/NavigatorTitleComponent.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../router/index.dart';

/// @author: wuwenqiang
/// @description: 用户管理页面 - 显示当前公司下的所有用户
/// @date: 2026-07-25
class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});

  @override
  UserManagePageState createState() => UserManagePageState();
}

class UserManagePageState extends State<UserManagePage> {
  EasyRefreshController userController = EasyRefreshController();
  late ChatProvider chatProvider;
  int pageNum = 1;
  int total = 0;
  List<UserInfoModel> userList = [];
  TextEditingController searchController = TextEditingController(text: "");
  String keyword = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _getCompanyUsers();
    });
  }

  /// @author: wuwenqiang
  /// @description: 获取公司用户列表
  /// @date: 2026-07-25
  void _getCompanyUsers() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final companyId = chatProvider.currentCompanyId;

    if (companyId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择公司",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    getCompanyUsersService(companyId, pageNum, PAGE_SIZE, keyword)
        .then((res) {
      if (mounted) {
        setState(() {
          total = res.total ?? 0;
          if (pageNum == 1) {
            userList.clear();
          }
          res.data.forEach((item) {
            userList.add(UserInfoModel.fromJson(item));
          });
        });
      }
    }).catchError((error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "获取用户列表失败: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      }
    });
  }

  /// @author: wuwenqiang
  /// @description: 搜索用户
  /// @date: 2026-07-25
  void _onSearchUser() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final companyId = chatProvider.currentCompanyId;

    if (companyId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择公司",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    setState(() {
      keyword = searchController.text.trim();
      pageNum = 1;
      userList.clear();
      _getCompanyUsers();
    });
  }

  /// @author: wuwenqiang
  /// @description: 清空搜索
  /// @date: 2026-07-25
  void _onClearSearch() {
    setState(() {
      searchController.clear();
      keyword = "";
      pageNum = 1;
      userList.clear();
      _getCompanyUsers();
    });
  }

  /// @author: wuwenqiang
  /// @description: 跳转到添加用户页面
  /// @date: 2026-07-25
  void _onAddUser() {
    Routes.router.navigateTo(
      context,
      '/AddUserPage',
      replace: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context, listen: true);
    final companyName = chatProvider.currentCompany?.name ?? '用户管理';

    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
        top: true,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: <Widget>[
              // 标题栏 - 右侧显示加号图标
              NavigatorTitleComponent(
                title: companyName,
                icon: GestureDetector(
                  onTap: _onAddUser,
                  child: Image.asset(
                    "lib/assets/images/icon_add.png",
                    width: ThemeSize.smallIcon,
                    height: ThemeSize.smallIcon,
                  ),
                ),
              ),
              // 搜索框
              _buildSearchBar(),
              // 用户列表
              Expanded(
                flex: 1,
                child: userList.isEmpty
                    ? Container(
                        margin: ThemeStyle.paddingBox,
                        decoration: ThemeStyle.boxDecoration,
                        padding: ThemeStyle.padding,
                        child: const Center(
                          child: Text(
                            "暂无数据",
                            style: TextStyle(color: ThemeColors.gray),
                          ),
                        ),
                      )
                    : EasyRefresh(
                        controller: userController,
                        footer: ClassicalFooter(
                          loadText: '上拉加载',
                          loadReadyText: '准备加载',
                          loadingText: '加载中...',
                          loadedText: '加载完成',
                          noMoreText: '没有更多',
                          bgColor: Colors.transparent,
                          textColor: ThemeColors.gray,
                        ),
                        onLoad: () async {
                          if (pageNum * PAGE_SIZE < total) {
                            pageNum++;
                            _getCompanyUsers();
                          } else {
                            Fluttertoast.showToast(
                              msg: "已经到底了",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.blue,
                              textColor: Colors.white,
                              fontSize: ThemeSize.middleFont,
                            );
                          }
                        },
                        child: _buildUserList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建搜索框 - 胶囊形白色背景
  /// @date: 2026-07-25
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(ThemeSize.middleGap),
      height: ThemeSize.btnHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: TextField(
              controller: searchController,
              cursorColor: ThemeColors.gray,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "请输入工号/姓名",
                hintStyle: const TextStyle(
                  fontSize: ThemeSize.smallFont,
                  color: ThemeColors.gray,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: ThemeSize.middleGap,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          // 清空按钮
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _onClearSearch,
              child: Image.asset(
                "lib/assets/images/icon_clear.png",
                width: ThemeSize.smallIcon,
                height: ThemeSize.smallIcon,
              ),
            ),
          if (searchController.text.isNotEmpty)
            const SizedBox(width: ThemeSize.smallMargin),
          // 搜索按钮
          GestureDetector(
            onTap: _onSearchUser,
            child: Image.asset(
              "lib/assets/images/icon_search.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
          ),
          const SizedBox(width: ThemeSize.middleGap),
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建用户列表
  /// @date: 2026-07-25
  Widget _buildUserList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ThemeSize.middleGap),
      decoration: ThemeStyle.boxDecoration,
      padding: ThemeStyle.padding,
      child: Column(
        children: userList
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final user = entry.value;
              final isLast = index == userList.length - 1;
              // 判断是否为管理员（role > 0）
              // 修复：使用括号明确优先级
              final roleStr = user.role ?? '0';
              final roleInt = int.tryParse(roleStr) ?? 0;
              final isAdmin = roleInt > 0;

              return Container(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : ThemeSize.middleGap,
                  bottom: isLast ? 0 : ThemeSize.middleGap,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: isLast ? Colors.transparent : ThemeColors.gray,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AvaterComponent(
                      size: ThemeSize.smallAvater,
                      avater: user.avater ?? "",
                    ),
                    const SizedBox(width: ThemeSize.middleGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.username,
                                style: const TextStyle(
                                  fontSize: ThemeSize.normalFont,
                                  color: ThemeColors.mainTitle,
                                ),
                              ),
                              const SizedBox(width: ThemeSize.miniMargin),
                              // 管理员标签
                              if (isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ThemeSize.miniMargin,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.primary,
                                    borderRadius: BorderRadius.circular(
                                      ThemeSize.minBtnRadius,
                                    ),
                                  ),
                                  child: const Text(
                                    "管理员",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: ThemeSize.smallFont,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: ThemeSize.miniMargin),
                          Text(
                            user.userAccount,
                            style: const TextStyle(
                              fontSize: ThemeSize.smallFont,
                              color: ThemeColors.subTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(),
      ),
    );
  }
}