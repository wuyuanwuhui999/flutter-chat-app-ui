import 'package:flutter/material.dart';
import 'package:flutter_music_app/provider/ChatProvider.dart';
import 'package:flutter_music_app/theme/ThemeColors.dart';
import 'package:flutter_music_app/theme/ThemeStyle.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../common/constant.dart';
import '../model/DirectoryModel.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeSize.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/HttpUtil.dart';

/// @author: wuwenqiang
/// @description: 上传文档目录选择组件
/// @date: 2025-09-13
class UploadDirectoryComponent extends StatefulWidget {
  const UploadDirectoryComponent({
    super.key,
  });

  @override
  State<UploadDirectoryComponent> createState() =>
      _UploadDirectoryComponentState();
}

class _UploadDirectoryComponentState extends State<UploadDirectoryComponent> {
  List<DirectoryModel> directoryList = [
    DirectoryModel(
      id: "default",
      userId: "",
      directory: "默认文件夹",
      isSelected: false,
    )
  ];
  String directoryId = "";
  late ChatProvider chatProvider;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDirectoryList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 加载目录列表
  /// @date: 2025-09-13
  void _loadDirectoryList() {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // ✅ 使用 currentTenantId
    final tenantId = chatProvider.currentTenantId;

    if (tenantId.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '请先选择租户';
        });
      }
      return;
    }

    getDirectoryListService(tenantId)
        .then((res) {
      if (!mounted) return;

      // 重置目录列表，保留默认文件夹
      final List<DirectoryModel> tempList = [
        DirectoryModel(
          id: "default",
          userId: "",
          directory: "默认文件夹",
          isSelected: directoryId == "default",
        )
      ];

      for (var item in res.data) {
        final dir = DirectoryModel.fromJson(item);
        dir.isSelected = (dir.id == directoryId);
        tempList.add(dir);
      }

      setState(() {
        directoryList = tempList;
        isLoading = false;
        // 保存到 ChatProvider
        chatProvider.setDirectoryList(
          tempList.where((d) => d.id != "default").toList(),
        );
      });
    }).catchError((error) {
      debugPrint('加载目录列表失败: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '加载目录失败，请重试';
        });
      }
    });
  }

  /// @author: wuwenqiang
  /// @description: 选择目录
  /// @date: 2025-09-13
  void _selectDirectory(int index) {
    setState(() {
      // 取消所有选择
      for (var directory in directoryList) {
        directory.isSelected = false;
      }
      // 选择当前项目
      directoryList[index].isSelected = true;
      directoryId = directoryList[index].id;
    });
  }

  /// @author: wuwenqiang
  /// @description: 文档上传
  /// @date: 2025-09-13
  Future<void> _onUploadDoc() async {
    if (directoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个文件夹')),
      );
      return;
    }

    // 选择文件 - 只允许PDF和TXT格式
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return; // 用户取消了选择
    }

    final file = result.files.single;
    final fileName = file.name.toLowerCase();

    // 检查文件格式
    if (!fileName.endsWith('.pdf') && !fileName.endsWith('.txt')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只支持上传PDF和TXT格式的文档')),
      );
      return;
    }

    // 关闭弹窗
    if (mounted) {
      Navigator.of(context).pop();
    }

    // 显示loading对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('文件上传中...'),
            ],
          ),
        );
      },
    );

    try {
      final filePath = file.path!;
      final tenantId = chatProvider.currentTenantId;

      if (tenantId.isEmpty) {
        throw Exception('请先选择租户');
      }

      // 使用HttpUtil上传文件
      final httpUtil = HttpUtil.getInstance();
      final response = await httpUtil.uploadDoc(
        filePath: filePath,
        fileName: file.name,
        tenantId: tenantId,
        directoryId: directoryId,
      );

      // 关闭loading对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response.status == SUCCESS) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文件上传成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: ${response.msg ?? "未知错误"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 关闭loading对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上传失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// @author: wuwenqiang
  /// @description: 创建新目录
  /// @date: 2025-09-14
  void _onCreateDirectory() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('创建文件夹'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入文件夹名称',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入文件夹名称')),
                  );
                  return;
                }
                _createDirectory(name);
                Navigator.of(context).pop();
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  /// @author: wuwenqiang
  /// @description: 创建目录
  /// @date: 2025-09-14
  void _createDirectory(String name) {
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

    final directory = DirectoryModel(
      id: "",
      userId: "",
      directory: name,
      tenantId: tenantId,
    );

    createDirService(directory).then((res) {
      if (res.data != null) {
        final newDir = DirectoryModel.fromJson(res.data);
        newDir.isSelected = false;

        setState(() {
          directoryList.add(newDir);
        });

        // 更新 ChatProvider 中的目录列表
        chatProvider.addDirectory(newDir);

        Fluttertoast.showToast(
          msg: "创建成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: res.msg ?? "创建失败",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "创建失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context, listen: true);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(
                color: ThemeColors.gray,
                fontSize: ThemeSize.normalFont,
              ),
            ),
            const SizedBox(height: ThemeSize.middleGap),
            ElevatedButton(
              onPressed: _loadDirectoryList,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: ThemeColors.background),
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: ThemeStyle.boxDecoration,
                padding: ThemeStyle.padding,
                margin: ThemeStyle.padding,
                child: Column(
                  children: directoryList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isLast = index == directoryList.length - 1;

                    return Container(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : ThemeSize.middleGap,
                        bottom: isLast ? 0 : ThemeSize.middleGap,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1,
                            color: isLast
                                ? Colors.transparent
                                : ThemeColors.gray,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.directory,
                              style: const TextStyle(
                                fontSize: ThemeSize.normalFont,
                                color: ThemeColors.mainTitle,
                              ),
                            ),
                          ),
                          // 单选按钮
                          GestureDetector(
                            onTap: () => _selectDirectory(index),
                            child: Container(
                              width: ThemeSize.radioSize,
                              height: ThemeSize.radioSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: item.isSelected
                                      ? ThemeColors.primary
                                      : ThemeColors.gray,
                                  width: 2,
                                ),
                                color: item.isSelected
                                    ? ThemeColors.primary
                                    : Colors.transparent,
                              ),
                              child: item.isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: ThemeSize.middleFont,
                                      color: Colors.white,
                                    )
                                  : null,
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
        ),
        // 底部按钮
        Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          padding: ThemeStyle.padding,
          child: Row(
            children: [
              // 创建目录按钮
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _onCreateDirectory,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ThemeColors.primary),
                    backgroundColor: Colors.transparent,
                    foregroundColor: ThemeColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ThemeSize.bigRadius),
                    ),
                  ),
                  child: const Text(
                    '新建文件夹',
                    style: TextStyle(
                      fontSize: ThemeSize.middleFont,
                      color: ThemeColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ThemeSize.middleGap),
              // 确定按钮
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _onUploadDoc,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.transparent),
                    backgroundColor: ThemeColors.primary,
                    foregroundColor: ThemeColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ThemeSize.bigRadius),
                    ),
                  ),
                  child: const Text(
                    '确定',
                    style: TextStyle(
                      fontSize: ThemeSize.middleFont,
                      color: ThemeColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ThemeSize.middleGap),
              // 取消按钮
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: ThemeColors.white,
                    foregroundColor: ThemeColors.white,
                    side: const BorderSide(color: ThemeColors.subTitle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ThemeSize.bigRadius),
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      fontSize: ThemeSize.middleFont,
                      color: ThemeColors.subTitle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}