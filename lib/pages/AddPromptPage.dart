import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../provider/ChatProvider.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';

/// @author: wuwenqiang
/// @description: 添加提示词页面
/// @date: 2026-09-11
class AddPromptPage extends StatefulWidget {
  const AddPromptPage({super.key});

  @override
  AddPromptPageState createState() => AddPromptPageState();
}

class AddPromptPageState extends State<AddPromptPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isSubmitting = false;
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _promptController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  /// @author: wuwenqiang
  /// @description: 提交新增提示词
  /// @date: 2026-09-11
  void _onSubmit() {
    if (_isSubmitting) return;
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final tenantId = _chatProvider.currentTenantId;
    if (tenantId.isEmpty) {
      Fluttertoast.showToast(
        msg: "请先选择租户",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    insertPromptService(tenantId, prompt).then((res) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      if (res.data > 0) {
        Fluttertoast.showToast(
          msg: "添加成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
        Navigator.of(context).pop(true);
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
      setState(() {
        _isSubmitting = false;
      });
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
    final isValid = _promptController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // 标题栏
            _buildTitleBar(),
            // 内容区
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(ThemeSize.middleGap),
                child: Column(
                  children: [
                    // 表单卡片 - 占满剩余高度
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: ThemeStyle.boxDecoration,
                        padding: ThemeStyle.padding,
                        child: TextField(
                          controller: _promptController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: ThemeColors.gray,
                          decoration: const InputDecoration(
                            hintText: "请输入提示词内容",
                            hintStyle: TextStyle(
                              fontSize: ThemeSize.smallFont,
                              color: ThemeColors.gray,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: ThemeSize.middleGap),
                    // 底部按钮
                    _buildBottomButtons(isValid),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 标题栏
  /// @date: 2026-09-11
  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.middleGap,
        vertical: ThemeSize.smallMargin,
      ),
      decoration: const BoxDecoration(
        color: ThemeColors.white,
        border: Border(
          bottom: BorderSide(color: ThemeColors.gray, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Image.asset(
              "lib/assets/images/icon_back.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '添加提示词',
                style: const TextStyle(
                  fontSize: ThemeSize.normalFont,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
          ),
          const SizedBox(width: ThemeSize.smallIcon),
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 底部按钮
  /// @date: 2026-09-11
  Widget _buildBottomButtons(bool isValid) {
    return Row(
      children: [
        // 取消按钮
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ThemeColors.subTitle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
              ),
              minimumSize: const Size(0, ThemeSize.btnHeight),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                color: ThemeColors.subTitle,
                fontSize: ThemeSize.normalFont,
              ),
            ),
          ),
        ),
        const SizedBox(width: ThemeSize.middleGap),
        // 确定按钮
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: isValid && !_isSubmitting ? _onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? ThemeColors.primary : ThemeColors.gray,
              foregroundColor: Colors.white,
              disabledBackgroundColor: ThemeColors.gray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
              ),
              minimumSize: const Size(0, ThemeSize.btnHeight),
            ),
            child: _isSubmitting
                ? const SizedBox(
              height: ThemeSize.smallIcon,
              width: ThemeSize.smallIcon,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              '确定',
              style: TextStyle(
                color: Colors.white,
                fontSize: ThemeSize.normalFont,
              ),
            ),
          ),
        ),
      ],
    );
  }
}