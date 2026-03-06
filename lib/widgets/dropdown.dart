import 'package:flutter/material.dart';

class Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final void Function(T?) onChanged;

  const Dropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
    );
  }
}