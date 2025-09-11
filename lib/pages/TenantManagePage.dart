import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_music_app/component/AvaterComponent.dart';
import 'package:flutter_music_app/model/TenantUserModel.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  List<TenantUserModel>tenantUserList = [];

  @override
  void initState() {
    getTenantUserList();
    super.initState();
  }

  getTenantUserList(){
    chatProvider = Provider.of<ChatProvider>(context,listen: false);
    getTenantUserListService(chatProvider.tenantUser.tenantId,pageNum,PAGE_SIZE).then((res){
      setState(() {
        total = res.total!;
        res.data.forEach((item){
          tenantUserList.add(TenantUserModel.fromJson(item));
        });
      });
    });
  }

  ///@author: wuwenqiang
  ///@description: 取消管理员
  /// @date: 2025-09-11 22:08
  onCancelAdmin(TenantUserModel tenantUser){

  }

  ///@author: wuwenqiang
  ///@description: 添加管理员
  /// @date: 2025-09-11 22:08
  onAddAdmin(TenantUserModel tenantUser){

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
                    NavigatorTitleComponent(title: chatProvider.tenantUser.tenantName),
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
                            child:Container(
                                decoration: ThemeStyle.boxDecoration,
                                padding: ThemeStyle.padding,
                                margin: ThemeStyle.padding,
                                child: Column(
                              children: tenantUserList.asMap().entries.map((entry) {
                                return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 1, //宽度
                                          color: entry.key == tenantUserList.length - 1
                                              ? Colors.white
                                              : ThemeColors.disableColor, //边框颜色
                                        ),
                                      ),
                                    ),
                                    child: Slidable(
                                        endActionPane: ActionPane(
                                          motion: ScrollMotion(),
                                          children: [
                                            SlidableAction(
                                              padding: EdgeInsets.only(
                                                  top: ThemeSize.containerPadding),
                                              onPressed: (context) {
                                                if(entry.value.roleType > 1){
                                                  onCancelAdmin(entry.value);
                                                }else{
                                                  onAddAdmin(entry.value);
                                                }
                                              },
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              icon: Icons.delete,
                                              label: entry.value.roleType > 1 ? "取消管理员" : "设为管理员",
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                            padding: EdgeInsets.only(
                                                top: entry.key == 0 ? 0 :ThemeSize.containerPadding,
                                                bottom: entry.key == tenantUserList.length - 1
                                                    ? 0
                                                    : ThemeSize.containerPadding),
                                            child: Row(
                                              children: [
                                                AvaterComponent(size: ThemeSize.smallAvater,avater: entry.value.avatar??""),
                                                SizedBox(width: ThemeSize.containerPadding),
                                                Text(entry.value.username),
                                              ],
                                            )
                                        )));
                              }).toList())
                            )))
                  ],
                ))));
  }
}
