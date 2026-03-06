
// small uppercase label used above fields
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final String text;

  const Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.grey[500],
      ),
    );
  }
}
