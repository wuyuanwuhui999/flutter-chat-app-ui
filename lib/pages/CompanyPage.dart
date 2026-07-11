// lib/pages/CompanyPage.dart

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import '../model/CompanyModel.dart';
import '../model/UserInfoModel.dart';
import '../provider/ChatProvider.dart';
import '../provider/UserInfoProvider.dart';
import '../router/index.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import '../theme/ThemeStyle.dart';
import '../utils/LocalStorageUtils.dart';

/// 公司选择页面
class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  CompanyPageState createState() => CompanyPageState();
}

class CompanyPageState extends State<CompanyPage> {
  List<CompanyModel> _companyList = [];
  String _selectedCompanyId = '';
  bool _isLoading = true;
  late UserInfoProvider _userInfoProvider;

  // 缓存Key常量
  static const String COMPANY_ID_STORAGE_KEY = 'COMPANY_ID_STORAGE_KEY';

  @override
  void initState() {
    super.initState();
    _userInfoProvider = Provider.of<UserInfoProvider>(context, listen: false);
    _loadCompanyData();
  }

  /// 加载公司数据
  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 从缓存获取已保存的companyId
      final cachedCompanyId = await LocalStorageUtils.getCompanyId();

      // 2. 获取用户ID
      final userId = _userInfoProvider.userInfo?.id ?? '';

      // 3. 获取公司列表
      final response = await getCompanyListService();

      if (response.status == 'SUCCESS' && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final companyList = data
            .map((item) => CompanyModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // 4. 根据缓存的companyId查找匹配的公司
        String foundCompanyId = '';
        for (var company in companyList) {
          if (company.id == cachedCompanyId) {
            foundCompanyId = company.id;
            break;
          }
        }

        setState(() {
          _companyList = companyList;
          _selectedCompanyId = foundCompanyId;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载公司列表失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 选择公司并执行后续操作
  void _selectCompanyAndProceed(String companyId) {
    // 找到对应的公司对象
    CompanyModel? selectedCompany;
    for (var company in _companyList) {
      if (company.id == companyId) {
        selectedCompany = company;
        break;
      }
    }

    if (selectedCompany == null) {
      return;
    }

    // 保存公司信息到缓存和全局
    _saveCompanyInfo(selectedCompany);

    // 跳转到ChatPage
    Routes.router.navigateTo(context, '/ChatPage', replace: true);
  }

  /// 保存公司信息到缓存和全局
  void _saveCompanyInfo(CompanyModel company) {
    // 1. 保存companyId到缓存（拼接userId）
    final userId = _userInfoProvider.userInfo?.id ?? '';
    LocalStorageUtils.setCompanyId(company.id, userId);

    // 2. 保存当前公司对象到ChatProvider全局状态
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.setCurrentCompany(company);
  }

  /// 选择公司条目
  void _selectCompany(int index) {
    setState(() {
      _selectedCompanyId = _companyList[index].id;
    });
  }

  /// 确认选择
  void _confirmSelection() {
    if (_selectedCompanyId.isEmpty) return;
    _selectCompanyAndProceed(_selectedCompanyId);
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _companyList.isEmpty
                      ? _buildEmptyView()
                      : _buildCompanyList(),
            ),
            // 底部确定按钮
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  /// 标题栏
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
          // 返回按钮占位
          const SizedBox(width: ThemeSize.smallIcon),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '选择公司',
                style: const TextStyle(
                  fontSize: ThemeSize.normalFont,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
          ),
          // 关闭按钮占位
          const SizedBox(width: ThemeSize.smallIcon),
        ],
      ),
    );
  }

  /// 空状态视图
  Widget _buildEmptyView() {
    return const Center(
      child: Text(
        '暂无公司数据',
        style: TextStyle(
          color: ThemeColors.subTitle,
          fontSize: ThemeSize.normalFont,
        ),
      ),
    );
  }

  /// 公司列表 - 每个公司条目为白色圆角卡片，宽度100%
  Widget _buildCompanyList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      child: Column(
        children: _companyList.asMap().entries.map((entry) {
          final index = entry.key;
          final company = entry.value;
          final isSelected = _selectedCompanyId == company.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: ThemeSize.middleGap),
            child: _buildCompanyCard(index, company, isSelected),
          );
        }).toList(),
      ),
    );
  }

  /// 单个公司卡片 - 白色圆角背景，宽度100%，无边框
  Widget _buildCompanyCard(int index, CompanyModel company, bool isSelected) {
    return InkWell(
      onTap: () => _selectCompany(index),
      borderRadius: BorderRadius.circular(ThemeSize.middleRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ThemeSize.middleGap),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ThemeSize.middleRadius),
          // ✅ 无边框
        ),
        child: Row(
          children: [
            // 公司名称 - 选中时变为 primary 颜色
            Expanded(
              flex: 1,
              child: Text(
                company.name,
                style: TextStyle(
                  fontSize: ThemeSize.normalFont,
                  color: isSelected ? ThemeColors.primary : ThemeColors.mainTitle,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 选中时显示勾勾图标
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ThemeColors.primary,
                size: ThemeSize.middleIcon,
              ),
          ],
        ),
      ),
    );
  }

  /// 底部确定按钮 - 无白色背景
  Widget _buildConfirmButton() {
    final isEnabled = _selectedCompanyId.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(ThemeSize.middleGap),
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: ThemeSize.btnHeight,
        child: ElevatedButton(
          onPressed: isEnabled ? _confirmSelection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? ThemeColors.primary : ThemeColors.gray,
            foregroundColor: ThemeColors.white,
            disabledBackgroundColor: ThemeColors.gray,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeSize.btnHeight / 2),
            ),
            elevation: 0,
          ),
          child: const Text(
            '确定',
            style: TextStyle(
              fontSize: ThemeSize.normalFont,
              color: ThemeColors.white,
            ),
          ),
        ),
      ),
    );
  }
}