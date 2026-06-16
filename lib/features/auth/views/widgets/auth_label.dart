import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AuthLabel extends StatelessWidget {
  final String text;

  const AuthLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }
}
