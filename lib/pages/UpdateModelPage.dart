// lib/pages/UpdateModelPage.dart

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/model/AiModel.dart';
import 'package:flutter_chat_app/service/serverMethod.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeSize.dart';
import 'package:flutter_chat_app/theme/ThemeStyle.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// @author: wuwenqiang
/// @description: 更新模型页面
/// @date: 2026-07-25
class UpdateModelPage extends StatefulWidget {
  const UpdateModelPage({super.key});

  @override
  UpdateModelPageState createState() => UpdateModelPageState();
}

class UpdateModelPageState extends State<UpdateModelPage> {
  late AiModel _model;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  String _selectedType = 'online';
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 防止重复初始化
    if (_isInitialized) return;

    // 从路由参数获取模型对象
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AiModel) {
      _model = args;
      _nameController.text = _model.modelName;
      _baseUrlController.text = _model.baseUrl;
      _apiKeyController.text = _model.apiKey ?? '';
      _selectedType = _model.type;
      _isInitialized = true;
    } else {
      // 如果没有传入参数，返回上一页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          Fluttertoast.showToast(
            msg: '参数错误',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: ThemeSize.middleFont,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  /// @author: wuwenqiang
  /// @description: 判断表单是否有效
  /// @date: 2026-07-25
  bool _isFormValid() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_baseUrlController.text.trim().isEmpty) return false;
    // 当类型为 online 时，apiKey 必填
    if (_selectedType == 'online') {
      if (_apiKeyController.text.trim().isEmpty) return false;
    }
    return true;
  }

  /// @author: wuwenqiang
  /// @description: 提交更新
  /// @date: 2026-07-25
  void _onSubmit() {
    if (!_isFormValid() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final updatedModel = AiModel(
      id: _model.id,
      modelName: _nameController.text.trim(),
      type: _selectedType,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
      companyId: _model.companyId,
      updateTime: _model.updateTime,
      createTime: _model.createTime,
    );

    updateModelService(updatedModel)
        .then((res) {
      if (!mounted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _isLoading = false;
      });

      if (res.data > 0) {
        Fluttertoast.showToast(
          msg: '更新成功',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
        Navigator.of(context).pop(true);
      } else {
        Fluttertoast.showToast(
          msg: res.msg ?? '更新失败',
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
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: '更新失败: $error',
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
    // 如果尚未初始化，显示加载中
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: ThemeColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // 标题栏
            _buildTitleBar(),
            // 内容区域
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ThemeSize.middleGap),
                child: Column(
                  children: [
                    _buildFormCard(),
                    const SizedBox(height: ThemeSize.middleGap),
                    _buildSubmitButton(),
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
  /// @description: 构建标题栏
  /// @date: 2026-07-25
  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.middleGap,
        vertical: ThemeSize.smallMargin,
      ),
      decoration: const BoxDecoration(
        color: ThemeColors.white,
        border: Border(
          bottom: BorderSide(
            color: ThemeColors.gray,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Image.asset(
              "lib/assets/images/icon_back.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
          ),
          // 标题
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '更新模型',
                style: const TextStyle(
                  fontSize: ThemeSize.normalFont,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
          ),
          // 占位
          const SizedBox(width: ThemeSize.smallIcon),
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建表单卡片
  /// @date: 2026-07-25
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      decoration: const BoxDecoration(
        color: ThemeColors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeSize.middleRadius),
        ),
      ),
      child: Column(
        children: [
          // 模型名称
          _buildTextField(
            controller: _nameController,
            label: '模型名称',
            hint: '请输入模型名称',
            isRequired: true,
          ),
          const Divider(height: 1, color: ThemeColors.gray),
          const SizedBox(height: ThemeSize.middleGap),
          // 模型类型
          _buildTypeSelector(),
          const Divider(height: 1, color: ThemeColors.gray),
          const SizedBox(height: ThemeSize.middleGap),
          // API地址
          _buildTextField(
            controller: _baseUrlController,
            label: 'API地址',
            hint: '请输入API地址',
            isRequired: true,
          ),
          const Divider(height: 1, color: ThemeColors.gray),
          const SizedBox(height: ThemeSize.middleGap),
          // API Key
          _buildTextField(
            controller: _apiKeyController,
            label: 'API Key',
            hint: '请输入API Key',
            isRequired: _selectedType == 'online',
            obscureText: true,
          ),
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建文本输入框
  /// @date: 2026-07-25
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isRequired,
    bool obscureText = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 70,
          child: Row(
            children: [
              if (isRequired)
                Text(
                  '*',
                  style: TextStyle(color: ThemeColors.warn),
                ),
              Text(label),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            cursorColor: ThemeColors.gray,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: ThemeSize.smallFont,
                color: ThemeColors.gray,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ThemeSize.middleGap,
                vertical: 0,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建模型类型选择器
  /// @date: 2026-07-25
  Widget _buildTypeSelector() {
    return Row(
      children: [
        const SizedBox(
          width: 70,
          child: Row(
            children: [
              Text('*'),
              Text('模型类型'),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('在线模型'),
                  value: 'online',
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Ollama'),
                  value: 'ollama',
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建提交按钮
  /// @date: 2026-07-25
  Widget _buildSubmitButton() {
    final isValid = _isFormValid();
    return SizedBox(
      width: double.infinity,
      height: ThemeSize.btnHeight,
      child: ElevatedButton(
        onPressed: isValid && !_isLoading ? _onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? ThemeColors.primary : ThemeColors.gray,
          foregroundColor: ThemeColors.white,
          disabledBackgroundColor: ThemeColors.gray,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
          ),
          elevation: 0,
        ),
        child: _isLoading
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
                  fontSize: ThemeSize.normalFont,
                  color: ThemeColors.white,
                ),
              ),
      ),
    );
  }
}