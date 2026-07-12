// lib/pages/TenantManagePage.dart

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_music_app/component/AvaterComponent.dart';
import 'package:flutter_music_app/model/TenantUserModel.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
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
  int pageNum = 1;
  int total = 0;
  List<TenantUserModel> tenantUserList = [];
  TextEditingController searchController = TextEditingController(text: "");
  String keyword = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    // ✅ 跳转到 AddTenantUserPage，传递 tenantId
    Routes.router.navigateTo(
      context,
      '/AddTenantUserPage?tenantId=$tenantId',
      replace: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context, listen: true);
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
              // ✅ 设置文本垂直居中
              textAlignVertical: TextAlignVertical.center,
              // ✅ 修复：使用 EdgeInsets.zero 并配合 textAlignVertical 实现居中
              decoration: InputDecoration(
                hintText: "请输入工号/姓名/邮箱/电话",
                hintStyle: const TextStyle(
                  fontSize: ThemeSize.smallFont,
                  color: ThemeColors.gray,
                ),
                // ✅ 关键修复：将 contentPadding 的垂直方向设为 0
                // 配合 textAlignVertical: TextAlignVertical.center 实现完美居中
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: ThemeSize.middleGap,
                ),
                border: InputBorder.none,
                // ✅ 移除内部默认间距
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
  /// @description: 构建用户列表
  /// @date: 2026-07-11
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
                  enabled: !isOwner,
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          if (isAdmin) {
                            onCancelAdmin(index);
                          } else if (user.role == 0) {
                            onAddAdmin(index);
                          }
                        },
                        backgroundColor: isOwner
                            ? ThemeColors.gray
                            : ThemeColors.primary,
                        foregroundColor: Colors.white,
                        label: isAdmin ? "取消管理员" : "设为管理员",
                      ),
                    ],
                  ),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : ThemeSize.middleGap,
                      bottom: isLast ? 0 : ThemeSize.middleGap,
                    ),
                    child: Row(
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
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}