// lib/pages/AddUserPage.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_chat_app/common/constant.dart';
import 'package:flutter_chat_app/component/AvaterComponent.dart';
import 'package:flutter_chat_app/component/NavigatorTitleComponent.dart';
import 'package:flutter_chat_app/component/AddUserDialog.dart'; // ✅ 新增导入
import 'package:flutter_chat_app/model/CompanyModel.dart';
import 'package:flutter_chat_app/model/SearchUserModel.dart'; // ✅ 新增导入
import 'package:flutter_chat_app/model/DepartmentModel.dart';
import 'package:flutter_chat_app/model/PositionModel.dart';
import 'package:flutter_chat_app/model/UserInfoModel.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';

/// @author: wuwenqiang
/// @description: 添加用户页面 - 搜索用户并添加到公司
/// @date: 2026-07-25
class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  AddUserPageState createState() => AddUserPageState();
}

class AddUserPageState extends State<AddUserPage> {
  TextEditingController searchController = TextEditingController(text: "");
  List<SearchUserModel> searchList = [];
  late ChatProvider chatProvider;
  String inputValue = "";
  EasyRefreshController searchUserController = EasyRefreshController();
  int pageNum = 1;
  int total = 0;

  /// 防抖定时器
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    chatProvider = Provider.of<ChatProvider>(context, listen: false);

    /// 监听输入框变化，自动触发搜索（带防抖）
    searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    /// 取消防抖定时器
    _debounceTimer?.cancel();
    searchController.removeListener(_onSearchTextChanged);
    searchController.dispose();
    searchUserController.dispose();
    super.dispose();
  }

  /// @author: wuwenqiang
  /// @description: 搜索文本变化时触发（带防抖，300ms）
  /// @date: 2026-07-25
  void _onSearchTextChanged() {
    final value = searchController.text;
    setState(() {
      inputValue = value;
    });

    /// 取消之前的定时器
    _debounceTimer?.cancel();

    /// 如果输入为空，清空列表并重置状态
    if (value.trim().isEmpty) {
      setState(() {
        searchList.clear();
        pageNum = 1;
        total = 0;
      });
      return;
    }

    /// 设置防抖定时器，300ms 后执行搜索
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  /// @author: wuwenqiang
  /// @description: 执行搜索
  /// @date: 2026-07-25
  void _performSearch() {
    final keyword = searchController.text.trim();
    if (keyword.isEmpty) {
      return;
    }

    /// 重置列表和页码，重新搜索
    setState(() {
      searchList.clear();
      pageNum = 1;
    });
    _fetchSearchResults(reset: true);
  }

  /// @author: wuwenqiang
  /// @description: 获取搜索结果（支持分页）
  /// @date: 2026-07-25
  void _fetchSearchResults({bool reset = false}) {
    final companyId = chatProvider.currentCompanyId;
    final keyword = searchController.text.trim();

    if (companyId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择公司",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    if (keyword.isEmpty) {
      return;
    }

    searchUsersService(companyId, pageNum, PAGE_SIZE, keyword).then((res) {
      if (!mounted) return;
      setState(() {
        total = res.total ?? 0;
        if (reset) {
          searchList = res.data.map((item) => SearchUserModel.fromJson(item)).toList();
        } else {
          res.data.forEach((item) {
            searchList.add(SearchUserModel.fromJson(item));
          });
        }
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
  /// @description: 清空搜索内容
  /// @date: 2026-07-25
  void _clearSearch() {
    searchController.clear();
    setState(() {
      searchList.clear();
      inputValue = "";
      pageNum = 1;
      total = 0;
    });
    _debounceTimer?.cancel();
  }

  /// @author: wuwenqiang
  /// @description: 选择用户并添加到公司
  /// @date: 2026-07-25
  void _selectItem(int index) {
    final user = searchList[index];
    // 如果已经添加，不执行任何操作
    if (user.checked == 1) {
      return;
    }

    final companyId = chatProvider.currentCompanyId;
    final currentRole = chatProvider.currentCompanyRoleInt;

    if (companyId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择公司",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    // role == 0: 普通用户，无权限
    if (currentRole == 0) {
      Fluttertoast.showToast(
        msg: "您没有权限添加用户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    // role >= 1: 管理员（普通管理员或超级管理员），弹出对话框
    if (currentRole >= 1) {
      _showAddUserDialog(user);
      return;
    }

    // 其他未知情况
    Fluttertoast.showToast(
      msg: "无权限添加用户",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: ThemeSize.middleFont,
    );
  }

  /// @author: wuwenqiang
  /// @description: 显示添加用户对话框（仅超级管理员）
  /// @date: 2026-07-25
  void _showAddUserDialog(SearchUserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddUserDialog(
          user: user,
          companyId: chatProvider.currentCompanyId,
          onAddSuccess: () {
            // 添加成功后更新列表状态
            setState(() {
              user.checked = 1;
            });
          },
        );
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 添加用户到公司
  /// @date: 2026-07-25
  void _addUserToCompany(String userId, String companyId, int role, String? positionId) {
    addCompanyUserService(userId, companyId, role, positionId).then((res) {
      if (!mounted) return;
      // data > 0 表示添加成功（返回的 data 已经是 int 类型）
      if (res.data > 0) {
        // 更新列表中该用户的 checked 状态
        setState(() {
          final index = searchList.indexWhere((item) => item.id == userId);
          if (index != -1) {
            searchList[index].checked = 1;
          }
        });
        Fluttertoast.showToast(
          msg: "添加成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      } else {
        Fluttertoast.showToast(
          msg: res.msg ?? "添加失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            const NavigatorTitleComponent(title: "添加用户"),
            // 搜索框
            _buildSearchBar(),
            // 搜索结果列表
            searchList.isEmpty
                ? Container(
                    margin: ThemeStyle.paddingBox,
                    decoration: ThemeStyle.boxDecoration,
                    padding: ThemeStyle.padding * 2,
                    child: Center(
                      child: Text(
                        inputValue.isEmpty ? "请输入关键词搜索" : "暂无数据",
                        style: const TextStyle(color: ThemeColors.gray),
                      ),
                    ))
                : Expanded(
                    flex: 1,
                    child: _buildSearchResultList(),
                  ),
          ],
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
          // 搜索图标（左侧）
          const SizedBox(width: ThemeSize.middleGap),
          Image.asset(
            "lib/assets/images/icon_search.png",
            width: ThemeSize.smallIcon,
            height: ThemeSize.smallIcon,
          ),
          const SizedBox(width: ThemeSize.smallMargin),
          // 输入框
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
                  horizontal: 0,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          // 清空按钮
          if (inputValue.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Image.asset(
                "lib/assets/images/icon_clear.png",
                width: ThemeSize.smallIcon,
                height: ThemeSize.smallIcon,
              ),
            ),
          if (inputValue.isNotEmpty)
            const SizedBox(width: ThemeSize.smallMargin),
          const SizedBox(width: ThemeSize.middleGap),
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建搜索结果列表
  /// @date: 2026-07-25
  Widget _buildSearchResultList() {
    return EasyRefresh(
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
          _fetchSearchResults(reset: false);
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
                    color: isLast ? Colors.transparent : ThemeColors.gray,
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
                    onTap: () => _selectItem(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSize.smallMargin,
                        vertical: ThemeSize.miniMargin,
                      ),
                      decoration: BoxDecoration(
                        color: user.checked == 1 ? ThemeColors.gray : ThemeColors.primary,
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
    );
  }
}