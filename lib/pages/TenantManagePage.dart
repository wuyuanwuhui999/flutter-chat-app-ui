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
import '../component/AddTenantUserComponent.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../service/serverMethod.dart';
import '../component/NavigatorTitleComponent.dart';

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

  @override
  void initState() {
    super.initState();
    // 延迟执行，确保 provider 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getTenantUserList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 获取租户用户列表
  /// @date: 2025-09-11
  void getTenantUserList() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // ✅ 使用 currentTenantId
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

    getTenantUserListService(tenantId, pageNum, PAGE_SIZE)
        .then((res) {
      if (mounted) {
        setState(() {
          total = res.total!;
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

    searchUsersService(tenantId, searchController.text, pageNum, PAGE_SIZE)
        .then((res) {
      if (mounted) {
        setState(() {
          total = res.total!;
          tenantUserList.clear();
          res.data.forEach((item) {
            tenantUserList.add(TenantUserModel.fromJson(item));
          });
        });
      }
    }).catchError((error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "搜索失败: $error",
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
            // 创建新对象替换
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
  /// @description: 添加租户用户弹窗
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTenantUserDialog(
          tenantId: tenantId,
          onUserSelected: (TenantUserModel selectedUser) {
            // 添加用户到租户
            if (mounted) {
              setState(() {
                tenantUserList.add(selectedUser);
              });
            }
          },
        );
      },
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
              // ✅ 标题栏显示当前租户名称
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
              Container(
                margin: const EdgeInsets.all(ThemeSize.middleGap),
                padding: ThemeStyle.padding,
                decoration: ThemeStyle.boxDecoration,
                child: Container(
                  height: ThemeSize.btnHeight,
                  decoration: const BoxDecoration(
                    color: ThemeColors.background,
                    borderRadius: BorderRadius.all(
                      Radius.circular(ThemeSize.bigRadius),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: searchController,
                          cursorColor: ThemeColors.gray,
                          onChanged: (String value) {
                            setState(() {});
                          },
                          decoration: const InputDecoration(
                            hintText: "请输入工号/姓名/邮箱/电话",
                            hintStyle: TextStyle(
                              fontSize: ThemeSize.smallFont,
                              color: ThemeColors.gray,
                            ),
                            contentPadding: EdgeInsets.only(
                              left: ThemeSize.middleGap,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: ThemeSize.smallMargin),
                      if (searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            searchController.clear();
                            setState(() {
                              tenantUserList.clear();
                              pageNum = 1;
                              getTenantUserList();
                            });
                          },
                          child: Image.asset(
                            "lib/assets/images/icon_clear.png",
                            width: ThemeSize.smallIcon,
                            height: ThemeSize.smallIcon,
                          ),
                        ),
                      if (searchController.text.isNotEmpty)
                        const SizedBox(width: ThemeSize.smallMargin),
                      GestureDetector(
                        onTap: () {
                          tenantUserList.clear();
                          pageNum = 1;
                          onSearchUser();
                        },
                        child: Image.asset(
                          "lib/assets/images/icon_search.png",
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon,
                        ),
                      ),
                      const SizedBox(width: ThemeSize.smallMargin),
                    ],
                  ),
                ),
              ),
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
                            if (searchController.text.isNotEmpty) {
                              onSearchUser();
                            } else {
                              getTenantUserList();
                            }
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
                        child: Container(
                          decoration: ThemeStyle.boxDecoration,
                          padding: ThemeStyle.padding,
                          margin: ThemeStyle.padding,
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
                                      color: isLast
                                          ? Colors.transparent
                                          : ThemeColors.gray,
                                    ),
                                  ),
                                ),
                                child: Slidable(
                                  enabled: !isOwner, // 所有者不可操作
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
                                              Text(
                                                user.username,
                                                style: const TextStyle(
                                                  fontSize: ThemeSize.normalFont,
                                                  color: ThemeColors.mainTitle,
                                                ),
                                              ),
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
                                                    "所有者",
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}