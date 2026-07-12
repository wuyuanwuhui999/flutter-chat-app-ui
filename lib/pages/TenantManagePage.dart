// lib/pages/TenantManagePage.dart

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_chat_app/component/AvaterComponent.dart';
import 'package:flutter_chat_app/model/TenantUserModel.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/provider/UserInfoProvider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../common/constant.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../service/serverMethod.dart';
import '../component/NavigatorTitleComponent.dart';
import '../router/index.dart';

class TenantManagePage extends StatefulWidget {
  const TenantManagePage({super.key});

  @override
  TenantManagePageState createState() => TenantManagePageState();
}

class TenantManagePageState extends State<TenantManagePage> {
  EasyRefreshController tenantUserController = EasyRefreshController();
  late ChatProvider chatProvider;
  late UserInfoProvider userInfoProvider;
  int pageNum = 1;
  int total = 0;
  List<TenantUserModel> tenantUserList = [];
  TextEditingController searchController = TextEditingController(text: "");
  String keyword = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatProvider = Provider.of<ChatProvider>(context, listen: false);
      userInfoProvider = Provider.of<UserInfoProvider>(context, listen: false);
      getTenantUserList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 获取租户用户列表
  /// @date: 2025-09-11
  void getTenantUserList() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.currentTenantId;

    if (tenantId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择租户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    getTenantUserListService(tenantId, pageNum, PAGE_SIZE, keyword)
        .then((res) {
      if (mounted) {
        setState(() {
          total = res.total!;
          if (pageNum == 1) {
            tenantUserList.clear();
          }
          res.data.forEach((item) {
            tenantUserList.add(TenantUserModel.fromJson(item));
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
  /// @date: 2025-09-11
  void onSearchUser() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.currentTenantId;

    if (tenantId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择租户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    pageNum = 1;
    tenantUserList.clear();
    getTenantUserList();
  }

  /// @author: wuwenqiang
  /// @description: 清空搜索
  /// @date: 2025-09-11
  void onClearSearch() {
    setState(() {
      searchController.clear();
      keyword = "";
      pageNum = 1;
      tenantUserList.clear();
      getTenantUserList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 取消管理员
  /// @date: 2025-09-11 22:08
  void onCancelAdmin(int index) {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.currentTenantId;

    if (tenantId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择租户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    cancelAdminService(tenantId, tenantUserList[index].userId)
        .then((res) {
      if (res.status == SUCCESS) {
        Fluttertoast.showToast(
          msg: "取消管理员成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: ThemeSize.middleFont,
        );
        if (mounted) {
          setState(() {
            tenantUserList[index] = TenantUserModel.fromJson({
              ...tenantUserList[index].toJson(),
              'role': 0,
            });
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: res.msg ?? "取消管理员失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      }
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "操作失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 添加管理员
  /// @date: 2025-09-11 22:08
  void onAddAdmin(int index) {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.currentTenantId;

    if (tenantId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择租户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    addAdminService(tenantId, tenantUserList[index].userId)
        .then((res) {
      if (res.status == SUCCESS) {
        Fluttertoast.showToast(
          msg: "设置管理员成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: ThemeSize.middleFont,
        );
        if (mounted) {
          setState(() {
            tenantUserList[index] = TenantUserModel.fromJson({
              ...tenantUserList[index].toJson(),
              'role': 1,
            });
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: res.msg ?? "设置管理员失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      }
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "操作失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 删除租户用户
  /// @date: 2025-09-12 17:22
  void onDeleteTenantUser(int index) {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.currentTenantId;
    final userId = tenantUserList[index].userId;

    if (tenantId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择租户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    // 弹窗确认
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除用户 "${tenantUserList[index].username}" 吗？'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消', style: TextStyle(color: ThemeColors.subTitle)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _doDeleteTenantUser(index, tenantId, userId);
              },
              child: const Text('删除', style: TextStyle(color: ThemeColors.warn)),
            ),
          ],
        );
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 执行删除租户用户
  /// @date: 2025-09-12 17:22
  void _doDeleteTenantUser(int index, String tenantId, String userId) {
    deleteTenantUserService(tenantId, userId).then((res) {
      if (res.status == SUCCESS) {
        Fluttertoast.showToast(
          msg: "删除成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
        if (mounted) {
          setState(() {
            tenantUserList.removeAt(index);
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: res.msg ?? "删除失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      }
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "删除失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 跳转到添加租户用户页面
  /// @date: 2025-09-11 22:08
  void onAddTenantUser() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.currentTenantId;

    if (tenantId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择租户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    Routes.router.navigateTo(
      context,
      '/AddTenantUserPage',
      replace: false,
    );
  }

  /// @author: wuwenqiang
  /// @description: 判断是否显示删除按钮
  /// 规则：当前用户角色 > 0（即管理员或超级管理员）才显示删除按钮
  /// @date: 2026-07-12
  bool _shouldShowDeleteButton() {
    final currentRole = chatProvider.currentTenantRole;
    return currentRole > 0;
  }

  /// @author: wuwenqiang
  /// @description: 判断是否显示管理员操作按钮（设为管理员/取消管理员）
  /// 规则：
  /// 1. 当前用户必须是超级管理员（currentRole > 1）
  /// 2. 目标用户不能是超级管理员（role != 2）
  /// 3. 目标用户不能是当前登录用户自己
  /// @date: 2026-07-12
  bool _shouldShowAdminAction(int targetUserRole, String targetUserId) {
    final currentRole = chatProvider.currentTenantRole;
    final currentUserId = userInfoProvider.userInfo?.id ?? '';

    // 只有超级管理员（role > 1）才能操作
    if (currentRole <= 1) {
      return false;
    }

    // 不能操作超级管理员
    if (targetUserRole == 2) {
      return false;
    }

    // 不能操作自己
    if (targetUserId == currentUserId) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context, listen: true);
    userInfoProvider = Provider.of<UserInfoProvider>(context, listen: true);
    final tenantName = chatProvider.currentTenantName;

    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
        top: true,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: <Widget>[
              NavigatorTitleComponent(
                title: tenantName,
                icon: GestureDetector(
                  onTap: onAddTenantUser,
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
                child: tenantUserList.isEmpty
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
                  controller: tenantUserController,
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
                      getTenantUserList();
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
  /// @date: 2026-07-11
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
                hintText: "请输入工号/姓名/邮箱/电话",
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
              onTap: onClearSearch,
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
            onTap: () {
              if (searchController.text.isNotEmpty) {
                onSearchUser();
              }
            },
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
  /// @description: 构建用户列表 - 支持左滑显示删除/管理员操作
  /// @date: 2026-07-12
  Widget _buildUserList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ThemeSize.middleGap),
      decoration: ThemeStyle.boxDecoration,
      padding: ThemeStyle.padding,
      child: Column(
        children: tenantUserList
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key;
          final user = entry.value;
          final isLast = index == tenantUserList.length - 1;
          final isOwner = user.role == 2;
          final isAdmin = user.role == 1;
          final currentUserId = userInfoProvider.userInfo?.id ?? '';

          // 判断是否显示删除按钮
          final showDelete = _shouldShowDeleteButton() && !isOwner;

          // 判断是否显示管理员操作按钮（设为管理员/取消管理员）
          final showAdminAction = _shouldShowAdminAction(user.role, user.userId);

          // 确定管理员操作按钮的文本
          String adminActionText = '';
          if (showAdminAction) {
            adminActionText = isAdmin ? '取消管理员' : '设为管理员';
          }

          // 构建滑动操作按钮列表
          final List<Widget> actionWidgets = [];

          // 添加管理员操作按钮（如果显示）
          if (showAdminAction) {
            actionWidgets.add(
              _buildCustomSlidableAction(
                onPressed: () {
                  if (isAdmin) {
                    onCancelAdmin(index);
                  } else {
                    onAddAdmin(index);
                  }
                },
                backgroundColor: ThemeColors.primary,
                label: adminActionText,
              ),
            );
          }

          // 添加删除按钮（如果显示）
          if (showDelete) {
            actionWidgets.add(
              _buildCustomSlidableAction(
                onPressed: () {
                  onDeleteTenantUser(index);
                },
                backgroundColor: ThemeColors.warn,
                label: '删除',
              ),
            );
          }

          // 如果没有任何操作按钮，不启用 Slidable
          if (actionWidgets.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: isLast ? Colors.transparent : ThemeColors.gray,
                  ),
                ),
              ),
              child: Container(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : ThemeSize.middleGap,
                  bottom: isLast ? 0 : ThemeSize.middleGap,
                ),
                child: _buildUserItem(user, isOwner, isAdmin),
              ),
            );
          }

          // 启用 Slidable
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: isLast ? Colors.transparent : ThemeColors.gray,
                ),
              ),
            ),
            child: Slidable(
              key: ValueKey(user.userId),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                // 使用 extentRatio 让按钮宽度自适应
                extentRatio: actionWidgets.length * 0.4,
                children: actionWidgets,
              ),
              child: Container(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : ThemeSize.middleGap,
                  bottom: isLast ? 0 : ThemeSize.middleGap,
                ),
                child: _buildUserItem(user, isOwner, isAdmin),
              ),
            ),
          );
        })
            .toList(),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建自定义滑动操作按钮（使用 CustomSlidableAction 默认填充）
  /// @date: 2026-07-12
  Widget _buildCustomSlidableAction({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required String label,
  }) {
    return CustomSlidableAction(
      onPressed: (context) {
        onPressed();
      },
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.smallMargin,
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ThemeSize.normalFont,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建单个用户条目
  /// @date: 2026-07-12
  Widget _buildUserItem(TenantUserModel user, bool isOwner, bool isAdmin) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvaterComponent(
          size: ThemeSize.smallAvater,
          avater: user.avatar ?? "",
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
                  // 超级管理员标签
                  if (isOwner)
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
                        "超级管理员",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ThemeSize.smallFont,
                        ),
                      ),
                    )
                  else if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSize.miniMargin,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
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
    );
  }
}