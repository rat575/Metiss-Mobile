import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class MetricTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const MetricTab({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFB000) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: const Color(0xFFE5E8E7)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB000).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.primaryColor : const Color(0xFF889492),
          ),
        ),
      ),
    );
  }
}
