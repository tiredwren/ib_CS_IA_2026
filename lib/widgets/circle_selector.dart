// multi select for class days of week / product sizes

import 'package:flutter/material.dart';

class CircleSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final void Function(String) onToggle;

  const CircleSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final isSelected = selected.contains(item);
        return GestureDetector(
          onTap: () => onToggle(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFCC0000) : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}