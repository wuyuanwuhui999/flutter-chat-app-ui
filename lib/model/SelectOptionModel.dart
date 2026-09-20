/// @author: wuwenqiang
/// @description: 通用下拉选项模型（value 为接口参数字段值，label 为界面展示文案）
/// @date: 2026-09-20
class SelectOptionModel {
  /// 选项对应的接口参数值
  final String value;

  /// 选项在界面上展示的文案
  final String label;

  const SelectOptionModel({
    required this.value,
    required this.label,
  });

  /// 工厂模式-用这种模式可以省略New关键字
  factory SelectOptionModel.fromJson(dynamic json) {
    return SelectOptionModel(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}
