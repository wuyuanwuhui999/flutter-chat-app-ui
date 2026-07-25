import 'package:flutter/material.dart';
import '../component/AvaterComponent.dart';
import '../model/DepartmentModel.dart';
import '../model/PositionModel.dart';
import '../pages/AddUserPage.dart';
import '../provider/ChatProvider.dart';
import '../service/serverMethod.dart';
import '../theme/ThemeColors.dart';
import '../theme/ThemeSize.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../model/SearchUserModel.dart';

/// @author: wuwenqiang
/// @description: 添加用户对话框 - 选择角色、部门、职位
/// @date: 2026-07-25
class AddUserDialog extends StatefulWidget {
  final SearchUserModel user;
  final String companyId;
  final VoidCallback onAddSuccess;

  const AddUserDialog({
    super.key,
    required this.user,
    required this.companyId,
    required this.onAddSuccess,
  });

  @override
  AddUserDialogState createState() => AddUserDialogState();
}

class AddUserDialogState extends State<AddUserDialog> {
  int selectedRole = 0; // 0: 普通用户, 1: 管理员
  DepartmentModel? selectedDepartment;
  PositionModel? selectedPosition;
  List<DepartmentModel> departmentList = [];
  List<PositionModel> positionList = [];
  bool isLoadingDepartments = false;
  bool isLoadingPositions = false;
  bool isSubmitting = false;
  late ChatProvider chatProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _loadDepartments();
  }

  /// @author: wuwenqiang
  /// @description: 加载部门列表
  /// @date: 2026-07-25
  void _loadDepartments() {
    setState(() {
      isLoadingDepartments = true;
    });
    getDepartmentsService(widget.companyId).then((res) {
      if (!mounted) return;
      setState(() {
        isLoadingDepartments = false;
        departmentList = res.data.map((item) => DepartmentModel.fromJson(item)).toList();
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        isLoadingDepartments = false;
      });
      Fluttertoast.showToast(
        msg: "加载部门失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 加载职位列表
  /// @date: 2026-07-25
  void _loadPositions(String departmentId) {
    setState(() {
      isLoadingPositions = true;
      selectedPosition = null;
      positionList = [];
    });
    getPositionsService(departmentId).then((res) {
      if (!mounted) return;
      setState(() {
        isLoadingPositions = false;
        positionList = res.data.map((item) => PositionModel.fromJson(item)).toList();
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        isLoadingPositions = false;
      });
      Fluttertoast.showToast(
        msg: "加载职位失败: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
    });
  }

  /// @author: wuwenqiang
  /// @description: 确认添加
  /// @date: 2026-07-25
  void _confirmAdd() {
    if (isSubmitting) return;

    if (selectedDepartment == null) {
      Fluttertoast.showToast(
        msg: "请选择部门",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: ThemeSize.middleFont,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final positionId = selectedPosition?.id ?? '';
    addCompanyUserService(
      widget.user.id,
      widget.companyId,
      selectedRole,
      positionId,
    ).then((res) {
      if (!mounted) {
        setState(() {
          isSubmitting = false;
        });
        return;
      }
      setState(() {
        isSubmitting = false;
      });
      if (res.data != null && (res.data as int) > 0) {
        Navigator.of(context).pop();
        widget.onAddSuccess();
        Fluttertoast.showToast(
          msg: "添加成功",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: ThemeSize.middleFont,
        );
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
        isSubmitting = false;
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
    // 获取当前用户角色
    final currentRole = chatProvider.currentCompanyRoleInt;
    // 是否显示角色选择（只有超级管理员 role >= 2 才显示）
    final showRoleSelection = currentRole >= 2;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeSize.middleRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(ThemeSize.middleGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Center(
              child: Text(
                '添加用户',
                style: const TextStyle(
                  fontSize: ThemeSize.bigFont,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.mainTitle,
                ),
              ),
            ),
            const SizedBox(height: ThemeSize.middleGap),
            // 用户信息
            Row(
              children: [
                AvaterComponent(
                  size: ThemeSize.smallAvater,
                  avater: widget.user.avater ?? "",
                ),
                const SizedBox(width: ThemeSize.middleGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.username,
                        style: const TextStyle(
                          fontSize: ThemeSize.normalFont,
                          color: ThemeColors.mainTitle,
                        ),
                      ),
                      Text(
                        widget.user.userAccount,
                        style: const TextStyle(
                          fontSize: ThemeSize.smallFont,
                          color: ThemeColors.subTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.middleGap),
            const Divider(color: ThemeColors.gray),
            const SizedBox(height: ThemeSize.middleGap),
            // 角色选择（仅超级管理员显示）
            if (showRoleSelection) ...[
              Row(
                children: [
                  const Text(
                    '角色:',
                    style: TextStyle(
                      fontSize: ThemeSize.normalFont,
                      color: ThemeColors.mainTitle,
                    ),
                  ),
                  const SizedBox(width: ThemeSize.middleGap),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('普通用户'),
                            value: 0,
                            groupValue: selectedRole,
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('管理员'),
                            value: 1,
                            groupValue: selectedRole,
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
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
              ),
              const SizedBox(height: ThemeSize.middleGap),
            ],
            // 部门选择
            Row(
              children: [
                const Text(
                  '部门:',
                  style: TextStyle(
                    fontSize: ThemeSize.normalFont,
                    color: ThemeColors.mainTitle,
                  ),
                ),
                const SizedBox(width: ThemeSize.middleGap),
                Expanded(
                  child: isLoadingDepartments
                      ? const SizedBox(
                          height: ThemeSize.btnHeight,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonFormField<DepartmentModel>(
                          value: selectedDepartment,
                          isExpanded: true,
                          hint: const Text('请选择部门'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ThemeSize.minBtnRadius,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: ThemeSize.smallMargin,
                              vertical: 0,
                            ),
                          ),
                          items: departmentList.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(dept.departmentName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDepartment = value;
                              selectedPosition = null;
                              positionList = [];
                            });
                            if (value != null) {
                              _loadPositions(value.id);
                            }
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.middleGap),
            // 职位选择
            Row(
              children: [
                const Text(
                  '职位:',
                  style: TextStyle(
                    fontSize: ThemeSize.normalFont,
                    color: ThemeColors.mainTitle,
                  ),
                ),
                const SizedBox(width: ThemeSize.middleGap),
                Expanded(
                  child: isLoadingPositions
                      ? const SizedBox(
                          height: ThemeSize.btnHeight,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonFormField<PositionModel>(
                          value: selectedPosition,
                          isExpanded: true,
                          hint: const Text('请选择职位'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ThemeSize.minBtnRadius,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: ThemeSize.smallMargin,
                              vertical: 0,
                            ),
                          ),
                          items: positionList.map((pos) {
                            return DropdownMenuItem(
                              value: pos,
                              child: Text(pos.positionName),
                            );
                          }).toList(),
                          onChanged: selectedDepartment != null
                              ? (value) {
                                  setState(() {
                                    selectedPosition = value;
                                  });
                                }
                              : null,
                        ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.middleGap * 2),
            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ThemeColors.gray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ThemeSize.btnHeight / 2,
                        ),
                      ),
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
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _confirmAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ThemeSize.btnHeight / 2,
                        ),
                      ),
                    ),
                    child: isSubmitting
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
            ),
          ],
        ),
      ),
    );
  }
}