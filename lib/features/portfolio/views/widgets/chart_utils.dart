import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

TextSpan buildTooltipRow(String label, String value, Color color) {
  return TextSpan(
    children: [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF5A6664),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      TextSpan(
        text: value,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

String formatFullDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('MMMM d, yyyy').format(date);
  } catch (e) {
    return dateStr;
  }
}

String formatChartDate(String dateStr, String granularity) {
  try {
    final date = DateTime.parse(dateStr);
    if (granularity == 'daily') {
      return DateFormat('MMM d').format(date);
    } else if (granularity == 'monthly') {
      return DateFormat('MMM y').format(date);
    } else {
      return DateFormat('y').format(date);
    }
  } catch (e) {
    return dateStr;
  }
}
