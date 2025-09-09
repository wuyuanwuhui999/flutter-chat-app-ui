import 'package:flutter/material.dart';
import '../model/DirectoryModel.dart';
import '../theme/ThemeSize.dart';

// 有状态的目录列表组件（内部管理选中状态）
class DirectoryListComponent extends StatefulWidget {
  final List<DirectoryModel> directoryList;
  final Function(int index)? onItemSelected;
  final int? initiallySelectedIndex;

  const DirectoryListComponent({
    Key? key,
    required this.directoryList,
    this.onItemSelected,
    this.initiallySelectedIndex,
  }) : super(key: key);

  @override
  State<DirectoryListComponent> createState() => _DirectoryListComponentState();
}

class _DirectoryListComponentState extends State<DirectoryListComponent> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initiallySelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.directoryList.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey,
      ),
      itemBuilder: (context, index) {
        final directory = widget.directoryList[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: ThemeSize.containerPadding), // 上下间隔15
          padding: const EdgeInsets.symmetric(horizontal: ThemeSize.containerPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左边显示directory字段
              Expanded(
                child: Text(
                  directory.directory,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: ThemeSize.containerPadding),
              // 右边单选按钮
              GestureDetector(
                onTap: () => selectItem(index),
                child: Container(
                  width: ThemeSize.radioSize,
                  height: ThemeSize.radioSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: directory.isSelected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    color: directory.isSelected ? Colors.blue : Colors.transparent,
                  ),
                  child: directory.isSelected
                      ? const Icon(
                    Icons.check,
                    size: ThemeSize.middleFontSize,
                    color: Colors.white,
                  )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 选择项目的方法
  void selectItem(int index) {
    setState(() {
      // 取消所有选择
      for (var directory in widget.directoryList) {
        directory.isSelected = false;
      }
      // 选择当前项目
      widget.directoryList[index].isSelected = true;
      if(widget.onItemSelected != null)widget.onItemSelected!(index);
    });
  }
}