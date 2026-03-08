// text input, filled or outlined (bc options are cool)

import 'package:flutter/material.dart';

enum Style { filled, outlined } // can change between styles if designer wants

class TextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final String? prefixText;
  final int maxLines;
  final Style style;

  const TextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefix,
    this.prefixText,
    this.maxLines = 1,
    this.style = Style.filled,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = style == Style.filled;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        prefix: prefix,
        prefixText: prefixText,
        filled: isFilled,
        fillColor: isFilled ? const Color(0xFFF5F5F5) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isFilled ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isFilled ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}