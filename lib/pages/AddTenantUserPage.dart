
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_music_app/common/constant.dart';
import 'package:flutter_music_app/model/TenantUserModel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../model/UserInfoModel.dart';
import '../provider/ChatProvider.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../component/AvaterComponent.dart';
import '../component/DialogComponent.dart';

/// @author: wuwenqiang
/// @description: 添加租户用户弹窗组件
/// @date: 2026-07-12
class AddTenantUserPage extends StatefulWidget {
  final String tenantId;
  final Function(TenantUserModel)? onUserSelected; // 添加回调函数

  const AddTenantUserPage({
    super.key,
    required this.tenantId,
    this.onUserSelected, // 可选的回调
  });

  @override
  AddTenantUserPageState createState() => AddTenantUserPageState();
}

class AddTenantUserPageState extends State<AddTenantUserPage> {
  TextEditingController searchController = TextEditingController(text: "");
  List<UserInfoModel> searchList = [];
  late ChatProvider chatProvider;
  String inputValue = "";
  EasyRefreshController searchUserController = EasyRefreshController();
  int pageNum = 1;
  int total = 0;

  @override
  void initState() {
    super.initState();
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    searchUserController.dispose();
    super.dispose();
  }

  void onSearchUser() {
    // 从 ChatProvider 获取当前租户ID和公司ID
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final tenantId = chatProvider.currentTenantId;
    final companyId = chatProvider.currentCompanyId;

    // ✅ 使用命名参数调用，同时传入 tenantId 和 companyId
    searchTenantUsersService(
      tenantId,
      companyId,
      searchController.text,
      pageNum,
      PAGE_SIZE,
    ).then((res) {
      setState(() {
        total = res.total!;
        res.data.forEach((item) {
          searchList.add(UserInfoModel.fromJson(item));
        });
      });
    }).catchError((error) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "搜索失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 选择用户并添加
  /// @date: 2026-07-12
  void selectItem(int index) {
    final user = searchList[index];
    // 如果已经添加，不执行任何操作
    if (user.checked == 0 || user.checked == null) {
      addTenantUserService(
        chatProvider.currentTenantId,
        user.id ?? "",
      ).then((res) {
        if (!mounted) return;
        setState(() {
          user.checked = 1;
        });
        // 执行父组件传入的回调方法
        if (widget.onUserSelected != null) {
          widget.onUserSelected!(TenantUserModel.fromJson(res.data));
        }
        Fluttertoast.showToast(
          msg: "添加成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      }).catchError((error) {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: "添加失败: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogComponent(
      title: "添加用户",
      content: Container(
        decoration: const BoxDecoration(color: ThemeColors.background),
        child: Column(
          children: [
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
                          setState(() {
                            inputValue = value;
                          });
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
                    // 清空按钮
                    if (inputValue.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          searchController.clear();
                          setState(() {
                            searchList = [];
                            inputValue = "";
                          });
                        },
                        child: Image.asset(
                          "lib/assets/images/icon_clear.png",
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon,
                        ),
                      ),
                    if (inputValue.isNotEmpty)
                      const SizedBox(width: ThemeSize.smallMargin),
                    // 搜索按钮
                    GestureDetector(
                      onTap: () {
                        searchList.clear();
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
            // 搜索结果列表
            searchList.isEmpty
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
                : Expanded(
                    flex: 1,
                    child: EasyRefresh(
                      controller: searchUserController,
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
                          onSearchUser();
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
                        margin: const EdgeInsets.only(
                          left: ThemeSize.middleGap,
                          right: ThemeSize.middleGap,
                          bottom: ThemeSize.middleGap,
                        ),
                        decoration: ThemeStyle.boxDecoration,
                        padding: ThemeStyle.padding,
                        child: Column(
                          children: searchList.asMap().entries.map((item) {
                            final index = item.key;
                            final user = item.value;
                            final isLast = index == searchList.length - 1;

                            return Container(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : ThemeSize.middleGap,
                                bottom: isLast ? 0 : ThemeSize.middleGap,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isLast
                                        ? Colors.transparent
                                        : ThemeColors.gray,
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // 头像
                                  AvaterComponent(
                                    size: ThemeSize.smallAvater,
                                    avater: user.avater ?? "",
                                  ),
                                  const SizedBox(width: ThemeSize.middleGap),
                                  // 用户名 + 工号
                                  Expanded(
                                    flex: 1,
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
                                  // 添加/已添加 按钮
                                  GestureDetector(
                                    onTap: () => selectItem(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: ThemeSize.smallMargin,
                                        vertical: ThemeSize.miniMargin,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.checked == 1
                                            ? ThemeColors.gray
                                            : ThemeColors.primary,
                                        borderRadius: BorderRadius.circular(
                                          ThemeSize.minBtnRadius,
                                        ),
                                      ),
                                      child: Text(
                                        user.checked == 1 ? "已添加" : "添加",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: ThemeSize.smallFont,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }
}