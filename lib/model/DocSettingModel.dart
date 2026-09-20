import 'SelectOptionModel.dart';

/// @author: wuwenqiang
/// @description: 文档上传设置模型（权限 / 分割模式 / 分割大小）
/// @date: 2026-09-20
class DocSettingModel {
  /// 权限-私密
  static const String permissionPrivate = 'private';

  /// 权限-租户内公开
  static const String permissionTenant = 'tenant';

  /// 权限-公司内公开
  static const String permissionCompany = 'company';

  /// 分割模式-递归字符分割（推荐）
  static const String splitMethodRecursive = 'recursive';

  /// 分割模式-按段落分割
  static const String splitMethodParagraph = 'paragraph';

  /// 分割模式-按句子分割
  static const String splitMethodSentence = 'sentence';

  /// 分割模式-固定长度分割
  static const String splitMethodFixed = 'fixed';

  /// 固定长度分割时，分割大小的默认值
  static const int defaultChunkSize = 1000;

  /// 文档权限下拉选项：private-私密、tenant-租户内公开、company-公司内公开
  static const List<SelectOptionModel> permissionOptions = [
    SelectOptionModel(value: permissionPrivate, label: '私密'),
    SelectOptionModel(value: permissionTenant, label: '租户内公开'),
    SelectOptionModel(value: permissionCompany, label: '公司内公开'),
  ];

  /// 文档分割模式下拉选项
  static const List<SelectOptionModel> splitMethodOptions = [
    SelectOptionModel(value: splitMethodRecursive, label: '递归字符分割（推荐）'),
    SelectOptionModel(value: splitMethodParagraph, label: '按段落分割'),
    SelectOptionModel(value: splitMethodSentence, label: '按句子分割'),
    SelectOptionModel(value: splitMethodFixed, label: '固定长度分割'),
  ];

  /// 文档权限（对应接口参数 permission）
  String permission;

  /// 文档分割模式（对应接口参数 splitMethod）
  String splitMethod;

  /// 分割大小（对应接口参数 chunkSize，仅 splitMethod=fixed 时生效）
  int chunkSize;

  DocSettingModel({
    this.permission = permissionPrivate,
    this.splitMethod = splitMethodRecursive,
    this.chunkSize = defaultChunkSize,
  });

  /// 工厂模式-用这种模式可以省略New关键字
  factory DocSettingModel.fromJson(dynamic json) {
    return DocSettingModel(
      permission: json['permission'] ?? permissionPrivate,
      splitMethod: json['splitMethod'] ?? splitMethodRecursive,
      chunkSize: json['chunkSize'] == null
          ? defaultChunkSize
          : int.tryParse(json['chunkSize'].toString()) ?? defaultChunkSize,
    );
  }

  /// 是否为固定长度分割（只有该模式下才需要下发 chunkSize）
  bool get isFixedChunk => splitMethod == splitMethodFixed;

  /// 当前权限对应的界面展示文案
  String get permissionLabel => labelOf(permissionOptions, permission);

  /// 当前分割模式对应的界面展示文案
  String get splitMethodLabel => labelOf(splitMethodOptions, splitMethod);

  /// 根据选项值获取对应的界面展示文案
  static String labelOf(List<SelectOptionModel> options, String value) {
    for (final option in options) {
      if (option.value == value) {
        return option.label;
      }
    }
    return value;
  }

  /// 上传文档接口的 body 参数
  /// chunkSize 只在固定长度分割（fixed）时下发，其他分割模式不带该参数
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'permission': permission,
      'splitMethod': splitMethod,
    };
    if (isFixedChunk) {
      json['chunkSize'] = chunkSize;
    }
    return json;
  }

  /// 复制并覆盖部分字段（不修改原对象）
  DocSettingModel copyWith({
    String? permission,
    String? splitMethod,
    int? chunkSize,
  }) {
    return DocSettingModel(
      permission: permission ?? this.permission,
      splitMethod: splitMethod ?? this.splitMethod,
      chunkSize: chunkSize ?? this.chunkSize,
    );
  }
}
