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
    getTenantUserList();
    super.initState();
  }

  getTenantUserList() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    getTenantUserListService(
            chatProvider.tenantUser.tenantId, pageNum, PAGE_SIZE)
        .then((res) {
      setState(() {
        total = res.total!;
        res.data.forEach((item) {
          tenantUserList.add(TenantUserModel.fromJson(item));
        });
      });
    });
  }

  ///@author: wuwenqiang
  ///@description: 取消管理员
  /// @date: 2025-09-11 22:08
  onCancelAdmin(int index) {
    cancelAdminService(
            chatProvider.tenantUser.tenantId, tenantUserList[index].userId)
        .then((res) {
      Fluttertoast.showToast(
          msg: "取消管理员成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: ThemeSize.middleFontSize);
      setState(() {
        // 创建新对象替换
        tenantUserList[index] = TenantUserModel.fromJson({
          ...tenantUserList[index].toJson(),
          'roleType': 0,
        });
      });
    });
  }

  ///@author: wuwenqiang
  ///@description: 添加管理员
  /// @date: 2025-09-11 22:08
  onAddAdmin(int index) {
    addAdminService(
            chatProvider.tenantUser.tenantId, tenantUserList[index].userId)
        .then((res) {
      Fluttertoast.showToast(
          msg: "设置管理员成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: ThemeSize.middleFontSize);
      setState(() {
        tenantUserList[index] = TenantUserModel.fromJson({
          ...tenantUserList[index].toJson(),
          'roleType': 1,
        });
      });
    });
  }

  void onAddTenantUser() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTenantUserDialog(
          tenantId: chatProvider.tenantUser.tenantId,
          onUserSelected: (TenantUserModel selectedUser) {
            // 或者执行其他操作，比如添加用户到租户
            tenantUserList.add(selectedUser);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColors.colorBg,
        body: SafeArea(
            top: true,
            child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: <Widget>[
                    NavigatorTitleComponent(
                      title: chatProvider.tenantUser.tenantName,
                      icon: GestureDetector(
                          onTap: onAddTenantUser,
                          child: Image.asset("lib/assets/images/icon_add.png",
                              width: ThemeSize.smallIcon,
                              height: ThemeSize.smallIcon)),
                    ),
                    Expanded(
                        flex: 1,
                        child: EasyRefresh(
                            controller: tenantUserController,
                            footer: ClassicalFooter(
                              loadText: '上拉加载',
                              loadReadyText: '准备加载',
                              loadingText: '加载中...',
                              loadedText: '加载完成',
                              noMoreText: '没有更多',
                              bgColor: Colors.transparent,
                              textColor: ThemeColors.disableColor,
                            ),
                            onLoad: () async {
                              pageNum++;
                              if (total <= pageNum * PAGE_SIZE) {
                                Fluttertoast.showToast(
                                    msg: "已经到底了",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.blue,
                                    textColor: Colors.white,
                                    fontSize: ThemeSize.middleFontSize);
                              } else {
                                pageNum++;
                                getTenantUserList();
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
                                  return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            width: 1, //宽度
                                            color: entry.key ==
                                                    tenantUserList.length - 1
                                                ? Colors.white
                                                : ThemeColors
                                                    .disableColor, //边框颜色
                                          ),
                                        ),
                                      ),
                                      child: Slidable(
                                          enabled: entry.value.roleType != 2,
                                          endActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) {
                                                  if (entry.value.roleType ==
                                                      1) {
                                                    onCancelAdmin(entry.key);
                                                  } else if (entry
                                                          .value.roleType ==
                                                      0) {
                                                    onAddAdmin(entry.key);
                                                  }
                                                },
                                                backgroundColor:
                                                    entry.value.roleType == 2
                                                        ? ThemeColors
                                                            .disableColor
                                                        : Colors.red,
                                                foregroundColor: Colors.white,
                                                label: entry.value.roleType > 0
                                                    ? "取消管理员"
                                                    : "设为管理员",
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                              padding: EdgeInsets.only(
                                                  top: entry.key == 0
                                                      ? 0
                                                      : ThemeSize
                                                          .containerPadding,
                                                  bottom: entry.key ==
                                                          tenantUserList
                                                                  .length -
                                                              1
                                                      ? 0
                                                      : ThemeSize
                                                          .containerPadding),
                                              child: Row(
                                                children: [
                                                  AvaterComponent(
                                                      size:
                                                          ThemeSize.smallAvater,
                                                      avater:
                                                          entry.value.avatar ??
                                                              ""),
                                                  SizedBox(
                                                      width: ThemeSize
                                                          .containerPadding),
                                                  Text(entry.value.username),
                                                ],
                                              ))));
                                }).toList()))))
                  ],
                ))));
  }
}
