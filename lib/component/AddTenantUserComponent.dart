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
import 'AvaterComponent.dart';
import 'DialogComponent.dart';

class AddTenantUserDialog extends StatefulWidget {
  final String tenantId;
  final Function(TenantUserModel)? onUserSelected; // 添加回调函数

  const AddTenantUserDialog({
    super.key,
    required this.tenantId,
    this.onUserSelected, // 可选的回调
  });

  @override
  AddTenantUserDialogState createState() => AddTenantUserDialogState();
}

class AddTenantUserDialogState extends State<AddTenantUserDialog> {
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

  void onSearchUser() {
    searchUsersService(widget.tenantId, searchController.text,pageNum,PAGE_SIZE).then((res) {
      setState(() {
        total = res.total!;
        res.data.forEach((item) {
          searchList.add(UserInfoModel.fromJson(item));
        });
      });
    });
  }

  void selectItem(int index) {
    if (searchList[index].checked == 0 || searchList[index].checked == null) {
      addTenantUserService(
              chatProvider.tenantUser.tenantId, searchList[index].id ?? "")
          .then((res) {
        setState(() {
          searchList[index].checked = 1;
        });
        // 执行父组件传入的回调方法
        if (widget.onUserSelected != null) {
          widget.onUserSelected!(TenantUserModel.fromJson(res.data));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogComponent(
      title: "添加用户",
      content: Container(
        decoration: const BoxDecoration(color: ThemeColors.colorBg),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(ThemeSize.containerPadding),
              padding: ThemeStyle.padding,
              decoration: ThemeStyle.boxDecoration,
              child: Container(
                height: ThemeSize.buttonHeight,
                decoration: const BoxDecoration(
                    color: ThemeColors.colorBg,
                    borderRadius:
                        BorderRadius.all(Radius.circular(ThemeSize.bigRadius))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: searchController,
                        cursorColor: ThemeColors.grey,
                        onChanged: (String value) {
                          setState(() {
                            inputValue = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "请输入工号/姓名/邮箱/电话",
                          hintStyle: TextStyle(
                              fontSize: ThemeSize.smallFontSize,
                              color: ThemeColors.grey),
                          contentPadding:
                              EdgeInsets.only(left: ThemeSize.containerPadding),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: ThemeSize.smallMargin),
                    inputValue != ""
                        ? GestureDetector(
                            onTap: () {
                              searchController.clear();
                              setState(() {
                                searchList = [];
                              });
                            },
                            child: Image.asset(
                                "lib/assets/images/icon_clear.png",
                                width: ThemeSize.smallIcon,
                                height: ThemeSize.smallIcon),
                          )
                        : const SizedBox(),
                    searchController.text != ""
                        ? const SizedBox(width: ThemeSize.smallMargin)
                        : const SizedBox(),
                    GestureDetector(
                      onTap: (){
                        searchList.clear();
                        onSearchUser();
                      },
                      child: Image.asset("lib/assets/images/icon_search.png",
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon),
                    ),
                    const SizedBox(width: ThemeSize.smallMargin)
                  ],
                ),
              ),
            ),
            searchList.isEmpty
                ? Container(
                    margin: ThemeStyle.paddingBox,
                    decoration: ThemeStyle.boxDecoration,
                    padding: ThemeStyle.padding,
                    child: const Center(
                        child: Text("暂无数据",
                            style: TextStyle(color: ThemeColors.disableColor))),
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
                        textColor: ThemeColors.disableColor,
                      ),
                      onLoad: () async {
                        if(pageNum * PAGE_SIZE < total){
                          pageNum++;
                          onSearchUser();
                        }else{
                          Fluttertoast.showToast(
                          msg: "已经到底了",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.blue,
                          textColor: Colors.white,
                          fontSize: ThemeSize.middleFontSize);
                        }
                      },
                      child: Container(
                          margin: const EdgeInsets.only(
                              left: ThemeSize.containerPadding,
                              right: ThemeSize.containerPadding,
                              bottom: ThemeSize.containerPadding),
                          decoration: ThemeStyle.boxDecoration,
                          padding: ThemeStyle.padding,
                          child: Column(
                              children: searchList.asMap().entries.map((item) {
                            return Container(
                                padding: EdgeInsets.only(
                                    top: item.key == 0
                                        ? 0
                                        : ThemeSize.containerPadding,
                                    bottom: item.key == searchList.length - 1
                                        ? 0
                                        : ThemeSize.containerPadding),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            // 设置单侧边框的样式
                                            color: item.key ==
                                                    searchList.length - 1
                                                ? Colors.transparent
                                                : ThemeColors.borderColor,
                                            width: 1,
                                            style: BorderStyle.solid))),
                                child: Row(children: [
                                  AvaterComponent(
                                      size: ThemeSize.smallAvater,
                                      avater: item.value.avater ?? ""),
                                  const SizedBox(
                                      width: ThemeSize.containerPadding),
                                  Expanded(
                                    flex: 1,
                                    child: Text(item.value.username),
                                  ),
                                  // 右边单选按钮
                                  GestureDetector(
                                    onTap: () => selectItem(item.key),
                                    child: Image.asset(
                                        item.value.checked == 1
                                            ? "lib/assets/images/icon_add_tenant_active.png"
                                            : "lib/assets/images/icon_add_tenant.png",
                                        width: ThemeSize.smallIcon,
                                        height: ThemeSize.smallIcon),
                                  )
                                ]));
                          }).toList())),
                    )
                    // SingleChildScrollView(child:
                    //     Container(
                    //       margin: const EdgeInsets.only(left: ThemeSize.containerPadding,right: ThemeSize.containerPadding,bottom: ThemeSize.containerPadding),
                    //       decoration: ThemeStyle.boxDecoration,
                    //       padding: ThemeStyle.padding,
                    //       child: Column(children: searchList.asMap().entries.map((item){
                    //         return Container(
                    //           padding: EdgeInsets.only(top: item.key == 0 ? 0 : ThemeSize.containerPadding,bottom: item.key == searchList.length - 1 ? 0 : ThemeSize.containerPadding),
                    //         decoration: BoxDecoration(border: Border(
                    //             bottom: BorderSide(
                    //               // 设置单侧边框的样式
                    //                 color: item.key == searchList.length - 1 ? Colors.transparent : ThemeColors.borderColor,
                    //                 width: 1,
                    //                 style: BorderStyle.solid))
                    //         ),child: Row(
                    //           children: [
                    //             AvaterComponent(size: ThemeSize.smallAvater,avater: item.value.avater??""),
                    //             const SizedBox(width: ThemeSize.containerPadding),
                    //             Expanded(flex: 1,child: Text(item.value.username),),
                    //             // 右边单选按钮
                    //             GestureDetector(
                    //               onTap: () => selectItem(item.key),
                    //               child: Container(
                    //                 width: ThemeSize.radioSize,
                    //                 height: ThemeSize.radioSize,
                    //                 decoration: BoxDecoration(
                    //                   shape: BoxShape.circle,
                    //                   border: Border.all(
                    //                     color: item.value.checked == 1 ? Colors.blue : Colors.grey,
                    //                     width: 2,
                    //                   ),
                    //                   color: item.value.checked == 1 ? Colors.blue : Colors.transparent,
                    //                 ),
                    //                 child: item.value.checked == 1
                    //                     ? const Icon(
                    //                   Icons.check,
                    //                   size: ThemeSize.middleFontSize,
                    //                   color: Colors.white,
                    //                 )
                    //                     : null,
                    //               ),
                    //             )
                    //           ]
                    //         ));
                    //       }).toList())
                    //     )
                    //   ,)
                    // ListView.separated(
                    //   shrinkWrap: true,
                    //   physics: const AlwaysScrollableScrollPhysics(),
                    //   itemCount: searchList.length,
                    //   separatorBuilder: (context, index) => const Divider(
                    //     height: 1,
                    //     thickness: 1,
                    //     color: Colors.grey,
                    //   ),
                    //   itemBuilder: (context, index) {
                    //     final user = searchList[index];
                    //     return Container(
                    //       margin: const EdgeInsets.symmetric(vertical: ThemeSize.containerPadding),
                    //       padding: const EdgeInsets.symmetric(horizontal: ThemeSize.containerPadding),
                    //       child: Row(
                    //         children: [
                    //           AvaterComponent(
                    //               size: ThemeSize.smallAvater,
                    //               avater: user.avater ?? ""
                    //           ),
                    //           const SizedBox(width: ThemeSize.smallMargin),
                    //           Expanded(flex: 1,child:Text(user.username)),
                    //           const SizedBox(width: ThemeSize.containerPadding),
                    //           GestureDetector(
                    //             onTap: () => selectItem(index),
                    //             child: Container(
                    //               width: ThemeSize.radioSize,
                    //               height: ThemeSize.radioSize,
                    //               decoration: BoxDecoration(
                    //                 shape: BoxShape.circle,
                    //                 border: Border.all(
                    //                   color: user.checked == 1 ? Colors.blue : Colors.grey,
                    //                   width: 2,
                    //                 ),
                    //                 color: user.checked == 1 ? Colors.blue : Colors.transparent,
                    //               ),
                    //               child: user.checked == 1
                    //                   ? Image.asset("lib/")
                    //                   : null,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     );
                    //   },
                    // ),
                    )
          ],
        ),
      ),
    );
  }
}
