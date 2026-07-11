import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_music_app/component/DocListComponent.dart';
import 'package:flutter_music_app/model/DirectoryModel.dart';
import 'package:flutter_music_app/model/DocModel.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api.dart';
import '../model/TenantModel.dart';
import '../component/CustomDialogComponent.dart';
import '../component/DialogComponent.dart';
import '../component/DocumentListComponent.dart';
import '../component/BottomSelectionDialog.dart';
import '../component/TriangleComponent.dart';
import '../component/UploadDirectoryComponent.dart';
import '../enum/ConnectionStatus.dart';
import '../enum/PositionEnum.dart';
import '../model/AiModel.dart';
import '../component/AvaterComponent.dart';
import '../model/ChatHistoryGroupModel.dart';
import '../model/ChatHistoryModel.dart';
import '../model/ChatModel.dart';
import '../model/TenantUserModel.dart';
import '../service/serverMethod.dart';
import '../provider/UserInfoProvider.dart';
import '../theme/ThemeStyle.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeColors.dart';
import '../common/constant.dart';
import '../utils/LocalStorageUtils.dart';
import '../utils/common.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  List<AiModel> modelList = [];
  String activeModelName = "";
  int pageNum = 1;
  int total = 0;
  String prompt = "";
  bool loading = false;
  String token = "";
  String chatId = generateSecureID();
  WebSocketChannel? channel;
  String message = "";
  StreamSubscription? subscription; // 保存订阅对象
  String thinkContent = "";
  String responseContent = "";
  String type = "";
  bool showThink = false;
  List<ChatModel> chatList = [
    ChatModel(
        position: PositionEnum.left,
        thinkContent: "",
        responseContent: "你好，我是智能音乐助手小吴同学，请问有什么可以帮助您？"),
  ];
  Map<String, List<List<ChatHistoryModel>>> timeAgoGroupMap = {};
  late ChatProvider chatProvider;
  late UserInfoProvider userInfoProvider;
  bool showHistory = false;
  List<DocModel> myDocList = [];
  EasyRefreshController historyEasyRefreshController = EasyRefreshController();
  TextEditingController controller = TextEditingController(); // 姓名
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  // 使用正则表达式进行匹配
  final RegExp startThinkPattern = RegExp(r'^<think>');
  final RegExp endThinkPattern = RegExp(r'</think>');
  bool showClearIcon = false;
  ScrollController scrollController = ScrollController();
  String language = "zh";
  String directoryId = "";
  String uploadDirId = "";
  List<String>docIds = [];

  @override
  void initState() {
    super.initState();

    // 初始化 Provider
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    userInfoProvider = Provider.of<UserInfoProvider>(context, listen: false);

    // 获取 Token
    LocalStorageUtils.getToken().then((res) {
      token = res;
    });

    // ✅ 加载租户列表（在加载模型列表之前）
    _loadTenantListAndModel();
  }

  /// @author: wuwenqiang
  /// @description: 加载模型列表
  /// @date: 2026-07-11
  void _loadModelList() {
    final companyId = chatProvider.currentCompanyId;

    getModelListService(companyId: companyId).then((res) {
      final models = res.data.map((item) => AiModel.fromJson(item)).toList();
      setState(() {
        modelList = models;
        activeModelName = models.isNotEmpty ? models.first.modelName : '';
      });
    }).catchError((error) {
      debugPrint('加载模型列表失败: $error');
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    // 1. 取消订阅（停止监听消息）
    subscription?.cancel();

    // 2. 关闭连接
    channel?.sink.close();

    // 3. 释放资源
    subscription = null;
    channel = null;
    super.dispose(); // 最后调用父类dispose
  }

  useHistory() {
    getChatHistoryService(pageNum, PAGE_SIZE).then((res) {
      List<dynamic> items =
          res.data.map((item) => ChatHistoryModel.fromJson(item)).toList();

      // 按chatId分组
      final chatIdGroup = <String, List<ChatHistoryModel>>{};
      for (var item in items) {
        chatIdGroup.putIfAbsent(item.chatId, () => []);
        chatIdGroup[item.chatId]!.add(item);
      }

      // 反转每个chatId组内的顺序
      for (var key in chatIdGroup.keys) {
        chatIdGroup[key] = chatIdGroup[key]!.reversed.toList();
      }

      // 按timeAgo分组
      final mTimeAgoGroupMap = <String, List<List<ChatHistoryModel>>>{};
      for (var chatIdList in chatIdGroup.values) {
        if (chatIdList.isNotEmpty) {
          final timeAgo = chatIdList.first.timeAgo ?? "";
          mTimeAgoGroupMap.putIfAbsent(timeAgo, () => []);
          mTimeAgoGroupMap[timeAgo]!.add(chatIdList);
        }
      }

      // 转换为最终分组结构
      final groups = mTimeAgoGroupMap.entries
          .map((entry) => ChatHistoryGroupModel(
                timeAgo: entry.key,
                list: entry.value,
              ))
          .toList();

      // 按时间倒序排序
      groups.sort((a, b) {
        // 这里简化排序逻辑，实际应根据时间值排序
        return b.timeAgo.compareTo(a.timeAgo);
      });
      setState(() {
        total = res.total!;
        timeAgoGroupMap = mTimeAgoGroupMap;
      });
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 关闭 WebSocket 连接
  closeWebSocket() {
    if (subscription != null) {
      subscription!.cancel();
      subscription = null;
    }

    if (channel != null) {
      try {
        channel!.sink.close();
      } catch (e) {
        debugPrint('关闭 WebSocket 时出错: $e');
      } finally {
        channel = null;
      }
    }
    setState(() {
      _connectionStatus = ConnectionStatus.disconnected;
      loading = false;
    });
  }

  useWebsocket() {
    if (!prompt.isNotEmpty) {
      return Fluttertoast.showToast(
          msg: "请输入聊天内容",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont);
    } else if (loading) {
      return;
    }
    setState(() {
      chatList.add(ChatModel(
          thinkContent: "",
          position: PositionEnum.right,
          responseContent: controller.text));
    });
    scrollToBottom();
    // 如果已有连接但未连接成功，先关闭旧连接
    channel = IOWebSocketChannel.connect(
      "${HOST.replaceAll("http", "ws")}${servicePath['chatWs']}", // 免费测试服务器
      pingInterval: const Duration(seconds: 30), // 心跳检测
    );

    subscription = channel?.stream.listen((value) {
      message += value;
      setState(() {
        loading = true;
        _connectionStatus = ConnectionStatus.connected;
        if (value != "[completed]") {
          // 使用正则提取内容
          // 检查当前消息是否符合条件
          if (startThinkPattern.hasMatch(message) &&
              endThinkPattern.hasMatch(message) &&
              !endThinkPattern.hasMatch(value)) {
            // 追加到响应内容
            responseContent += value;
          } else {
            // 追加到思考内容
            thinkContent += value;
          }
        } else {
          //对话已完成
          message = "";
          loading = false;
          chatList.add(ChatModel(
            responseContent: responseContent,
            thinkContent: thinkContent,
            position: PositionEnum.left,
          ));
          thinkContent = responseContent = "";
        }
      });
      scrollToBottom();
    }, onError: (error) {
      setState(() {
        _connectionStatus = ConnectionStatus.error;
        loading = false;
        Fluttertoast.showToast(msg: "连接错误: $error");
      });
    }, onDone: () {
      closeWebSocket();
    });
    chatId = chatId.isNotEmpty ? chatId : generateSecureID();
    Map<String, dynamic> payload = {
      "modelName": activeModelName,
      "token": token, // 替换为实际用户ID
      "chatId": chatId, // 替换为实际聊天ID
      "docIds": docIds,
      "prompt": prompt,
      "type": type,
      "showThink": showThink,
      "language": language
    };
    controller.text = "";

    channel?.sink.add(json.encode(payload));
    setState(() {
      prompt = "";
      loading = true;
    });
  }

  void useTabModel() {
    BottomSelectionDialog.show(
      context: context,
      options: modelList.map((item) {
        return item.modelName;
      }).toList(),
      selectedOption: activeModelName, // ✅ 传入当前选中的模型名称
      onTap: (String selectedOption, int index) {
        setState(() {
          activeModelName = selectedOption;
        });
      },
    );
  }

  ///@author: wuwenqiang
  ///@description: 文档设置弹窗
  /// @date: 2025-09-08 16:23
  Future<void> showDocSettingDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DialogComponent(
            showDivider: false,
            title: "选择文档",
            content:
                DocumentListComponent(onItemSelected: (List<String> checkDocIds) {
                  docIds = checkDocIds;
                  print(docIds);
            }));
      },
    );
  }

  ///@author: wuwenqiang
  ///@description: 文档设置弹窗
  /// @date: 2025-09-13 10:59
  onUploadDoc() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return DialogComponent(
              showDivider: false,
              leftIcon: IconButton(
                  onPressed: onCreateDirectory, icon: const Icon(Icons.add)),
              title: "选择文档目录",
              content: const UploadDirectoryComponent());
        });
  }

  ///@author: wuwenqiang
  ///@description: 创建文件夹
  /// @date: 2025-09-14 09:37
  ///@author: wuwenqiang
  ///@description: 创建文件夹
  /// @date: 2025-09-14 09:37
  onCreateDirectory() {
    TextEditingController directoryNameController = TextEditingController();
    CustomDialogComponent(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.only(top: ThemeSize.middleGap),
            child: Row(
              children: [
                const Text("文件夹名称"),
                const SizedBox(width: ThemeSize.smallMargin),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.gray, // 灰色背景
                      borderRadius:
                          BorderRadius.circular(ThemeSize.middleRadius), // 圆角
                    ),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.top,
                      controller: directoryNameController,
                      cursorColor: ThemeColors.subTitle,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(
                          left: ThemeSize.miniMargin,
                          right: ThemeSize.miniMargin,
                          top: ThemeSize.miniMargin,
                          bottom: ThemeSize.miniMargin,
                        ),
                        hintText: '请输入文件夹名称',
                        hintStyle: TextStyle(
                          fontSize: ThemeSize.smallFont,
                          color: ThemeColors.subTitle,
                        ),
                        border: InputBorder.none,
                        // 移除边框
                        enabledBorder: InputBorder.none,
                        // 移除启用状态边框
                        focusedBorder: InputBorder.none,
                        // 移除聚焦状态边框
                        disabledBorder: InputBorder.none,
                        // 移除禁用状态边框
                        errorBorder: InputBorder.none,
                        // 移除错误状态边框
                        focusedErrorBorder: InputBorder.none, // 移除聚焦错误状态边框
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
        name: "创建文件夹",
        okCallback: () {
          createDirService(DirectoryModel(
                  id: "",
                  userId: "",
                  directory: directoryNameController.text,
                  tenantId: chatProvider.currentTenantId))
              .then((res) {
            if (res.data != null) {
              Fluttertoast.showToast(msg: "创建成功");
              chatProvider.addDirectory(DirectoryModel.fromJson(res.data));
            } else {
              Fluttertoast.showToast(msg: res.msg ?? "创建失败");
            }
          });
        }).show();
  }

  /// @author: wuwenqiang
  /// @description: 头部标题栏，显示"当前租户名称 | 当选模型名称"
  /// 点击租户名称弹出租户选择框，点击模型名称弹出模型选择框
  /// @date: 2026-07-11
  Widget buildHeaderWidget() {
    // 获取当前租户名称和模型名称
    final tenantName = chatProvider.currentTenantName;
    final modelName = activeModelName.isNotEmpty ? activeModelName : '未选择模型';

    return Container(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      decoration: const BoxDecoration(color: ThemeColors.white),
      child: Row(
        children: [
          // 头像
          AvaterComponent(
            size: ThemeSize.smallAvater,
            avater: userInfoProvider.userInfo.avater ?? "",
          ),
          const SizedBox(width: ThemeSize.smallMargin),

          // ✅ 标题：点击租户名称弹出选择框
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _showTenantSelectionDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 租户名称（带下划线装饰，表示可点击）
                  Text(
                    tenantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: ThemeSize.miniMargin),
                  // 分隔符
                  const Text(
                    "|",
                    style: TextStyle(
                      fontSize: ThemeSize.normalFont,
                      color: ThemeColors.gray,
                    ),
                  ),
                  const SizedBox(width: ThemeSize.miniMargin),
                  // ✅ 模型名称（可点击）
                  GestureDetector(
                    onTap: _showModelSelectionDialog,
                    child: Text(
                      modelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 菜单按钮
          PopupMenuButton<String>(
            color: ThemeColors.popupMenu.withOpacity(1),
            child: Image.asset(
              'lib/assets/images/icon_menu.png',
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
            onSelected: (String item) {
              if (item == "上传文档") {
                onUploadDoc();
              } else if (item == "我的文档") {
                onShowDocList();
              } else if (item == "会话记录") {
                setState(() {
                  showHistory = true;
                });
                useHistory();
              }
              // ❌ 移除了 "切换模型" 选项
            },
            itemBuilder: (context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: "上传文档",
                  child: Text(
                    "上传文档",
                    style: TextStyle(color: ThemeColors.white),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem<String>(
                  value: "我的文档",
                  child: Text(
                    "我的文档",
                    style: TextStyle(color: ThemeColors.gray),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem<String>(
                  value: "会话记录",
                  child: Text(
                    "会话记录",
                    style: TextStyle(color: ThemeColors.gray),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 显示租户选择对话框
  /// @date: 2026-07-11
  void _showTenantSelectionDialog() {
    final tenantList = chatProvider.tenantList;

    if (tenantList.isEmpty) {
      Fluttertoast.showToast(
        msg: "暂无租户可切换",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // 获取当前选中的租户ID
    final currentTenantId = chatProvider.currentTenantId;

    // 构建选项列表：租户名称 + (当前租户显示 ✓)
    final options = tenantList.map((item) {
      return item.name;
    }).toList();

    // 使用 BottomSelectionDialog 组件
    BottomSelectionDialog.show(
      context: context,
      options: options,
      selectedOption: tenantList.firstWhere(
        (t) => t.id == currentTenantId,
        orElse: () => tenantList.first,
      ).name,
      onTap: (String selectedName, int index) {
        final selectedTenant = tenantList[index];

        // 如果选择的是当前租户，不做任何操作
        if (selectedTenant.id == currentTenantId) {
          Fluttertoast.showToast(
            msg: "当前已是该租户",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
          return;
        }

        // 切换租户
        chatProvider.setCurrentTenant(selectedTenant);

        // ✅ 清空聊天对话，只显示欢迎问候语
        setState(() {
          chatList = [
            ChatModel(
              position: PositionEnum.left,
              thinkContent: "",
              responseContent: "你好，我是智能音乐助手小吴同学，请问有什么可以帮助您？",
            )
          ];
          // 重置聊天ID，生成新的会话
          chatId = generateSecureID();
          // 清空文档选择
          docIds = [];
          // 重置思考内容和响应内容
          thinkContent = "";
          responseContent = "";
          // 关闭WebSocket连接（如果有）
          closeWebSocket();
        });

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

  /// @author: wuwenqiang
  /// @description: 显示模型选择对话框
  /// @date: 2026-07-11
  void _showModelSelectionDialog() {
    if (modelList.isEmpty) {
      Fluttertoast.showToast(
        msg: "暂无模型可选",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // 构建选项列表：模型名称
    final options = modelList.map((item) => item.modelName).toList();

    // 使用 BottomSelectionDialog 组件
    BottomSelectionDialog.show(
      context: context,
      options: options,
      selectedOption: activeModelName,
      onTap: (String selectedOption, int index) {
        setState(() {
          activeModelName = selectedOption;
          // 切换模型时，如果有WebSocket连接，关闭并重置聊天状态
          if (channel != null || subscription != null) {
            closeWebSocket();
            // 重置聊天列表，保留欢迎语
            chatList = [
              ChatModel(
                position: PositionEnum.left,
                thinkContent: "",
                responseContent: "你好，我是智能音乐助手小吴同学，请问有什么可以帮助您？",
              )
            ];
            chatId = generateSecureID();
            thinkContent = "";
            responseContent = "";
          }
        });

        Fluttertoast.showToast(
          msg: "已切换到模型: $selectedOption",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 加载租户列表和模型列表
  /// @date: 2026-07-11
  void _loadTenantListAndModel() {
    final companyId = chatProvider.currentCompanyId;
    final userId = userInfoProvider.userInfo?.id ?? '';

    // 1. 获取租户列表
    getTenantListService(companyId).then((res) {
      if (res.data.isNotEmpty) {
        // 解析租户列表
        final tenantList = res.data
            .map((item) => TenantModel.fromJson(item))
            .toList();

        // 保存到 ChatProvider
        chatProvider.setTenantList(tenantList);

        // 2. 从缓存获取租户ID
        LocalStorageUtils.getTenantId().then((cachedTenantId) {
          TenantModel? targetTenant;

          // 根据缓存查找租户
          if (cachedTenantId.isNotEmpty) {
            targetTenant = chatProvider.getTenantById(cachedTenantId);
          }

          // 如果缓存中没有或找不到，使用第一条
          if (targetTenant == null && tenantList.isNotEmpty) {
            targetTenant = tenantList.first;
          }

          // 设置当前租户
          if (targetTenant != null) {
            chatProvider.setCurrentTenant(targetTenant);

            // ✅ 更新UI - 刷新标题栏显示当前租户名称
            setState(() {});
          }
        });
      }
    }).catchError((error) {
      debugPrint('加载租户列表失败: $error');
    });

    // 3. 获取模型列表（独立进行）
    _loadModelList();
  }

  Widget buildChatList() {
    return Expanded(
        flex: 1,
        child: ListView(
            controller: scrollController, // 绑定控制器
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.only(
                bottom: ThemeSize.middleGap,
                left: ThemeSize.middleGap,
                right: ThemeSize.middleGap),
            children: [
              ...chatList.map((item) {
                return Padding(
                    padding:
                        const EdgeInsets.only(top: ThemeSize.middleGap),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PositionEnum.left == item.position
                            ? Container(
                                margin: const EdgeInsets.only(
                                    top: ThemeSize.smallMargin),
                                child: Row(
                                  children: [
                                    Image.asset('lib/assets/images/icon_ai.png',
                                        width: ThemeSize.middleIcon,
                                        height: ThemeSize.middleIcon),
                                    const SizedBox(width: ThemeSize.miniMargin),
                                    const TriangleComponent(
                                        size: ThemeSize.miniIcon,
                                        color: Colors.white),
                                  ],
                                ),
                              )
                            : const SizedBox(),
                        Expanded(
                            flex: 1,
                            child: Wrap(
                              alignment: PositionEnum.left == item.position
                                  ? WrapAlignment.start
                                  : WrapAlignment.end,
                              children: [
                                Container(
                                    padding: ThemeStyle.padding,
                                    decoration: ThemeStyle.boxDecoration,
                                    child: Column(
                                      children: [
                                        item.thinkContent != ""
                                            ? Text(
                                                item.thinkContent ?? "",
                                                style: const TextStyle(
                                                    color:
                                                        ThemeColors.subTitle),
                                              )
                                            : const SizedBox(),
                                        Text(item.responseContent ?? ""),
                                      ],
                                    ))
                              ],
                            )),
                        PositionEnum.right == item.position
                            ? Container(
                                margin: const EdgeInsets.only(
                                    top: ThemeSize.smallMargin),
                                child: Row(
                                  children: [
                                    Transform.rotate(
                                      angle: pi, // 旋转-90度（π/2弧度）
                                      child: const TriangleComponent(
                                          size: ThemeSize.miniIcon,
                                          color: Colors.white),
                                    ),
                                    AvaterComponent(
                                      size: ThemeSize.middleIcon,
                                      avater:
                                          userInfoProvider.userInfo.avater ??
                                              "",
                                    )
                                  ],
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ));
              }),
              loading
                  ? Padding(
                      padding: const EdgeInsets.only(
                          top: ThemeSize.middleGap),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                                top: ThemeSize.smallMargin),
                            child: Row(
                              children: [
                                Image.asset('lib/assets/images/icon_ai.png',
                                    width: ThemeSize.middleIcon,
                                    height: ThemeSize.middleIcon),
                                const SizedBox(width: ThemeSize.miniMargin),
                                const TriangleComponent(
                                    size: ThemeSize.miniIcon,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                          Expanded(
                              flex: 1,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                children: [
                                  Container(
                                    padding: ThemeStyle.padding,
                                    decoration: ThemeStyle.boxDecoration,
                                    child: Column(
                                      children: [
                                        Text(
                                          thinkContent.isEmpty
                                              ? "正在思考中"
                                              : thinkContent,
                                          style: const TextStyle(
                                              color: ThemeColors.gray),
                                        ),
                                        responseContent.isNotEmpty
                                            ? Text(responseContent)
                                            : const SizedBox(),
                                      ],
                                    ),
                                  )
                                ],
                              ))
                        ],
                      ))
                  : const SizedBox()
            ]));
  }

  Widget buildTypeWidget() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(ThemeSize.smallMargin),
          decoration: const BoxDecoration(color: ThemeColors.background),
          child: Row(
            children: [
              OutlinedButton(
                  onPressed: () {
                    setState(() {
                      showThink = !showThink;
                    });
                  },

                  ///圆角
                  style: OutlinedButton.styleFrom(
                    backgroundColor: ThemeColors.white,
                    foregroundColor: ThemeColors.white,
                    side: BorderSide(
                        color:
                            showThink ? ThemeColors.primary : ThemeColors.subTitle),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ThemeSize.bigRadius), // 圆角
                    ),
                  ),
                  child: Text(
                    '深度思考',
                    style: TextStyle(
                        fontSize: ThemeSize.middleFont,
                        color:
                            showThink ? ThemeColors.primary : ThemeColors.subTitle),
                  )),
              const SizedBox(width: ThemeSize.middleGap),
              OutlinedButton(
                  onPressed: () {
                    setState(() {
                      type = type == "document" ? "" : "document";
                    });
                  },

                  ///圆角
                  style: OutlinedButton.styleFrom(
                    backgroundColor: ThemeColors.white,
                    // 背景色（可选）
                    foregroundColor: ThemeColors.white,
                    // 文字颜色
                    side: BorderSide(
                        color: type == "document"
                            ? ThemeColors.primary
                            : ThemeColors.subTitle),
                    // 设置边框颜色（这里是黑色）
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ThemeSize.bigRadius), // 圆角
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '查询文档',
                        style: TextStyle(
                            fontSize: ThemeSize.middleFont,
                            color: type == "document"
                                ? ThemeColors.primary
                                : ThemeColors.subTitle),
                      ),
                      SizedBox(width: ThemeSize.smallMargin),
                      GestureDetector(
                        onTap: (){
                          if(type == "document"){
                            showDocSettingDialog(context);
                          }else{
                            setState(() {
                              type = "document";
                            });
                          }
                        },
                        child: Image.asset(type == "document" ? 'lib/assets/images/icon_setting_active.png' : "lib/assets/images/icon_setting_disabled.png",
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon),)
                      ,
                    ],
                  )),
              SizedBox(width: ThemeSize.middleGap),
              OutlinedButton(
                  onPressed: () {
                    setState(() {
                      language = language == "zh" ? "en" : "zh";
                    });
                  },

                  ///圆角
                  style: OutlinedButton.styleFrom(
                    backgroundColor: ThemeColors.white,
                    // 背景色（可选）
                    foregroundColor: ThemeColors.white,
                    // 文字颜色
                    side: BorderSide(
                        color: type == "db"
                            ? ThemeColors.primary
                            : ThemeColors.subTitle),
                    // 设置边框颜色（这里是黑色）
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ThemeSize.bigRadius), // 圆角
                    ),
                  ),
                  child: Row(children: [
                    Text(language == "zh" ? "中文" : "英文",
                        style: const TextStyle(
                            color: ThemeColors.mainTitle,
                            fontSize: ThemeSize.middleFont)),
                    const SizedBox(width: ThemeSize.miniMargin),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..scale(language == "zh" ? 1.0 : -1.0, 1.0),
                      // 根据参数决定是否翻转
                      child: Image.asset(
                        "lib/assets/images/icon_switch.png",
                        width: ThemeSize.smallIcon,
                        height: ThemeSize.smallIcon,
                      ),
                    )
                  ]))
            ],
          ),
        ));
  }

  Widget buildInputWidget() {
    return Container(
        padding: ThemeStyle.padding,
        decoration: const BoxDecoration(color: ThemeColors.white),
        child: Row(children: [
          GestureDetector(
            onTap: () {
              setState(() {
                chatList = [];
                chatId = "";
              });
            },
            child: Image.asset("lib/assets/images/icon_chat.png",
                width: ThemeSize.middleIcon, height: ThemeSize.middleIcon),
          ),
          const SizedBox(width: ThemeSize.middleGap),
          Expanded(
              flex: 1,
              child: Container(
                  height: ThemeSize.btnHeight,
                  //修饰黑色背景与圆角
                  decoration: const BoxDecoration(
                    color: ThemeColors.background,
                    borderRadius: BorderRadius.all(
                        Radius.circular(ThemeSize.superRadius)),
                  ),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.only(left: ThemeSize.smallMargin * 2),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          flex: 1,
                          child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  prompt = value;
                                });
                              },
                              controller: controller,
                              cursorColor: ThemeColors.gray, //设置光标
                              decoration: const InputDecoration(
                                hintText: "有问题，尽管问",
                                hintStyle: TextStyle(
                                    fontSize: ThemeSize.smallFont,
                                    color: ThemeColors.gray),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                    bottom: ThemeSize.smallMargin),
                              ))),
                      prompt != ""
                          ? InkWell(
                              onTap: () {
                                setState(() {
                                  controller.text = ""; //清除输入框的值
                                });
                              },
                              child: Image.asset(
                                "lib/assets/images/icon_clear.png",
                                height: ThemeSize.smallIcon,
                                width: ThemeSize.smallIcon,
                              ))
                          : const SizedBox(),
                      const SizedBox(width: ThemeSize.smallMargin)
                    ],
                  ))),
          const SizedBox(width: ThemeSize.middleGap),
          GestureDetector(
              onTap: useWebsocket,
              child: Container(
                height: ThemeSize.btnHeight,
                width: ThemeSize.btnHeight,
                decoration: const BoxDecoration(
                  color: ThemeColors.background,
                  borderRadius:
                      BorderRadius.all(Radius.circular(ThemeSize.superRadius)),
                ),
                child: Center(
                  child: loading
                      ? Container(
                          width: ThemeSize.miniIcon,
                          height: ThemeSize.miniIcon,
                          decoration: const BoxDecoration(
                              color: ThemeColors.gray),
                        )
                      : Image.asset("lib/assets/images/icon_send.png",
                          width: ThemeSize.smallIcon,
                          height: ThemeSize.smallIcon),
                ),
              ))
        ]));
  }

  // 对话列表
  Widget buildChatWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width, // 使用实际屏幕宽度
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          buildHeaderWidget(),
          buildChatList(),
          buildTypeWidget(),
          buildInputWidget()
        ],
      ),
    );
  }

  // 历史记录弹窗
  Widget buildHistoryWidget() {
    return showHistory
        ? Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 0,
            child: SizedBox(
                width: MediaQuery.of(context).size.width, // 使用实际屏幕宽度
                height: MediaQuery.of(context).size.height,
                child: Row(children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: EasyRefresh(
                        controller: historyEasyRefreshController,
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
                          pageNum++;
                          if (total <= pageNum * PAGE_SIZE) {
                            Fluttertoast.showToast(
                                msg: "已经到底了",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.blue,
                                textColor: Colors.white,
                                fontSize: ThemeSize.middleFont);
                          } else {}
                        },
                        child: Container(
                            padding: ThemeStyle.padding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: timeAgoGroupMap.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((indexedEntry) {
                                final index = indexedEntry.key;
                                final item = indexedEntry.value;
                                final isLast =
                                    index == timeAgoGroupMap.entries.length - 1;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.key,
                                      style: const TextStyle(
                                          color: ThemeColors.gray),
                                    ),
                                    ...item.value.map((bItem) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            chatList.clear();
                                            chatId = bItem.first.chatId;
                                            showHistory = false;
                                            for (var cItem in bItem) {
                                              chatList
                                                ..add(ChatModel(
                                                    position:
                                                        PositionEnum.right,
                                                    responseContent:
                                                        cItem.prompt))
                                                ..add(ChatModel(
                                                    position: PositionEnum.left,
                                                    thinkContent:
                                                        cItem.thinkContent,
                                                    responseContent:
                                                        cItem.responseContent));
                                            }
                                          });
                                        },
                                        child: Text(bItem.first.prompt),
                                      );
                                    }),
                                    SizedBox(
                                        height: isLast
                                            ? 0
                                            : ThemeSize.middleGap)
                                  ],
                                );
                              }).toList(),
                            ))),
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showHistory = false;
                        });
                      },
                      child: Container(
                        decoration:
                            BoxDecoration(color: ThemeColors.popupMenu),
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                  )
                ])),
          )
        : const SizedBox();
  }

  onShowDocList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const DialogComponent(
            title: "我的文档", content: DocListComponent());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context, listen: true);
    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
          top: true,
          child: Stack(
            children: [buildChatWidget(), buildHistoryWidget()],
          )),
    );
  }
}
