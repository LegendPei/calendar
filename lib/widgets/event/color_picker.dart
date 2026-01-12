/// 颜色选择器组件
import 'package:flutter/material.dart';

/// 预设颜色列表
const List<int> presetColors = [
  0xFF1976D2, // 蓝色
  0xFF43A047, // 绿色
  0xFFE53935, // 红色
  0xFFFF9800, // 橙色
  0xFF9C27B0, // 紫色
  0xFF00BCD4, // 青色
  0xFF795548, // 棕色
  0xFF607D8B, // 灰蓝色
  0xFFE91E63, // 粉红色
  0xFF3F51B5, // 靛蓝色
  0xFF009688, // 蓝绿色
  0xFFFFEB3B, // 黄色
];

class ColorPicker extends StatelessWidget {
  /// 当前选中的颜色
  final int? selectedColor;

  /// 颜色选择回调
  final ValueChanged<int> onColorSelected;

  /// 是否显示取消选项
  final bool showNone;

  const ColorPicker({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
    this.showNone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showNone)
          _buildColorItem(
            context,
            null,
            isSelected: selectedColor == null,
          ),
        ...presetColors.map((color) => _buildColorItem(
          context,
          color,
          isSelected: selectedColor == color,
        )),
      ],
    );
  }

  Widget _buildColorItem(BuildContext context, int? color, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        if (color != null) {
          onColorSelected(color);
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color != null ? Color(color) : Colors.grey.shade200,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.black, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: color == null
            ? Icon(
                Icons.block,
                color: Colors.grey.shade400,
                size: 20,
              )
            : isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
      ),
    );
  }
}

/// 颜色选择对话框
Future<int?> showColorPickerDialog(BuildContext context, {int? initialColor}) async {
  return showDialog<int>(
    context: context,
    builder: (context) {
      int? selectedColor = initialColor;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('选择颜色'),
            content: ColorPicker(
              selectedColor: selectedColor,
              onColorSelected: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selectedColor),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
}

