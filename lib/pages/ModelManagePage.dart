import 'package:flutter/material.dart';
import 'package:flutter_chat_app/model/AiModel.dart';
import 'package:flutter_chat_app/provider/ChatProvider.dart';
import 'package:flutter_chat_app/service/serverMethod.dart';
import 'package:flutter_chat_app/theme/ThemeColors.dart';
import 'package:flutter_chat_app/theme/ThemeSize.dart';
import 'package:flutter_chat_app/theme/ThemeStyle.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../router/index.dart';

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
    Routes.router.navigateTo(
      context,
      '/AddModelPage',
      replace: false,
    ).then((_) {
      // 从添加页面返回时刷新列表
      _loadModelList();
    });
  }

  /// @author: wuwenqiang
  /// @description: 点击模型条目，跳转到更新模型页面
  /// @date: 2026-07-25
  void _onModelTap(AiModel model) {
    Routes.router.navigateTo(
      context,
      '/UpdateModelPage',
      replace: false,
      routeSettings: RouteSettings(arguments: model),
    ).then((_) {
      // 从更新页面返回时刷新列表
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
            Expanded(
              flex: 1,
              child: _buildContent(),
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

    return Padding(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      child: ListView.separated(
        itemCount: _modelList.length,
        separatorBuilder: (context, index) => const SizedBox(height: ThemeSize.middleGap),
        itemBuilder: (context, index) {
          final model = _modelList[index];
          return _buildModelCard(model);
        },
      ),
    );
  }

  /// @author: wuwenqiang
  /// @description: 构建单个模型卡片
  /// @date: 2026-07-25
  Widget _buildModelCard(AiModel model) {
    return GestureDetector(
      onTap: () => _onModelTap(model),
      child: Container(
        padding: const EdgeInsets.all(ThemeSize.middleGap),
        decoration: const BoxDecoration(
          color: ThemeColors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(ThemeSize.middleRadius),
          ),
        ),
        child: Row(
          children: [
            // 模型图标（首字母或默认图标）
            Container(
              width: ThemeSize.middleIcon,
              height: ThemeSize.middleIcon,
              decoration: BoxDecoration(
                color: _getTypeColor(model.type).withOpacity(0.15),
                borderRadius: BorderRadius.circular(ThemeSize.minBtnRadius),
              ),
              child: Center(
                child: Text(
                  model.modelName.isNotEmpty ? model.modelName[0].toUpperCase() : 'M',
                  style: TextStyle(
                    color: _getTypeColor(model.type),
                    fontSize: ThemeSize.middleFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ThemeSize.middleGap),
            // 模型名称
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.modelName,
                    style: const TextStyle(
                      fontSize: ThemeSize.normalFont,
                      color: ThemeColors.mainTitle,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: ThemeSize.miniMargin),
                  // 模型类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeSize.smallMargin,
                      vertical: 2,
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
                ],
              ),
            ),
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