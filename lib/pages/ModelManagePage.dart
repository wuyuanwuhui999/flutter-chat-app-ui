// lib/pages/ModelManagePage.dart

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/model/AiModel.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/service/serverMethod.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeSize.dart';
import 'package:flutter_chat_app/theme/ThemeStyle.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'AddModelPage.dart';
import 'UpdateModelPage.dart';

/// @author: wuwenqiang
/// @description: 模型管理页面 - 显示当前公司的所有模型列表
/// @date: 2026-07-25
class ModelManagePage extends StatefulWidget {
  const ModelManagePage({super.key});

  @override
  ModelManagePageState createState() => ModelManagePageState();
}

class ModelManagePageState extends State<ModelManagePage> {
  List<AiModel> _modelList = [];
  bool _isLoading = true;
  String? _errorMessage;
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _loadModelList();
  }

  /// @author: wuwenqiang
  /// @description: 加载模型列表
  /// @date: 2026-07-25
  void _loadModelList() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final companyId = _chatProvider.currentCompanyId;

    getModelListService(companyId: companyId)
        .then((res) {
      if (!mounted) return;

      if (res.status == 'SUCCESS' && res.data != null) {
        final models = (res.data as List)
            .map((item) => AiModel.fromJson(item))
            .toList();
        setState(() {
          _modelList = models;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.msg ?? '加载模型列表失败';
        });
      }
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载模型列表失败: $error';
      });
    });
  }

  /// @author: wuwenqiang
  /// @description: 跳转到添加模型页面
  /// @date: 2026-07-25
  void _onAddModel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddModelPage()),
    ).then((_) {
      _loadModelList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 点击模型条目，跳转到更新模型页面
  /// @date: 2026-07-25
  void _onModelTap(AiModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpdateModelPage(),
        settings: RouteSettings(arguments: model),
      ),
    ).then((_) {
      _loadModelList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 获取模型类型显示文本
  /// @date: 2026-07-25
  String _getTypeText(String type) {
    switch (type) {
      case 'online':
        return '在线模型';
      case 'ollama':
        return 'Ollama';
      default:
        return type;
    }
  }

  /// @author: wuwenqiang
  /// @description: 获取模型类型标签颜色
  /// @date: 2026-07-25
  Color _getTypeColor(String type) {
    switch (type) {
      case 'online':
        return ThemeColors.primary;
      case 'ollama':
        return Colors.blue;
      default:
        return ThemeColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // 标题栏
            _buildTitleBar(),
            // 内容区域
            _buildContent(),
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
                '模型管理',
                style: const TextStyle(
                  fontSize: ThemeSize.normalFont,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
          ),
          // 添加图标
          GestureDetector(
            onTap: _onAddModel,
            child: Image.asset(
              "lib/assets/images/icon_add.png",
              width: ThemeSize.smallIcon,
              height: ThemeSize.smallIcon,
            ),
          ),
        ],
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建内容区域
  /// @date: 2026-07-25
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: ThemeColors.gray,
                fontSize: ThemeSize.normalFont,
              ),
            ),
            const SizedBox(height: ThemeSize.middleGap),
            ElevatedButton(
              onPressed: _loadModelList,
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

    if (_modelList.isEmpty) {
      return const Center(
        child: Text(
          '暂无模型',
          style: TextStyle(
            color: ThemeColors.gray,
            fontSize: ThemeSize.normalFont,
          ),
        ),
      );
    }

    // 所有模型放在同一个卡片中
    return Padding(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      child: Container(
        decoration: const BoxDecoration(
          color: ThemeColors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(ThemeSize.middleRadius),
          ),
        ),
        child: Column(
          children: _modelList.asMap().entries.map((entry) {
            final index = entry.key;
            final model = entry.value;
            final isLast = index == _modelList.length - 1;

            return Column(
              children: [
                // 模型条目
                _buildModelItem(model),
                // 灰色横线（最后一个不显示）
                if (!isLast)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: ThemeSize.middleGap,
                    ),
                    height: 1,
                    color: ThemeColors.gray,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建单个模型条目
  /// @date: 2026-07-25
  Widget _buildModelItem(AiModel model) {
    return GestureDetector(
      onTap: () => _onModelTap(model),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSize.middleGap,
          vertical: ThemeSize.middleGap,
        ),
        child: Row(
          children: [
            // 模型名称
            Expanded(
              flex: 1,
              child: Text(
                model.modelName,
                style: const TextStyle(
                  fontSize: ThemeSize.normalFont,
                  color: ThemeColors.mainTitle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: ThemeSize.middleGap),
            // 模型类型标签
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeSize.smallMargin,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _getTypeColor(model.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(ThemeSize.minBtnRadius),
              ),
              child: Text(
                _getTypeText(model.type),
                style: TextStyle(
                  color: _getTypeColor(model.type),
                  fontSize: ThemeSize.smallFont,
                ),
              ),
            ),
            const SizedBox(width: ThemeSize.smallMargin),
            // 箭头图标
            Image.asset(
              "lib/assets/images/icon_arrow.png",
              width: ThemeSize.miniIcon,
              height: ThemeSize.miniIcon,
            ),
          ],
        ),
      ),
    );
  }
}