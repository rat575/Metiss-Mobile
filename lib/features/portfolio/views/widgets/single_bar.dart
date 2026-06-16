import 'package:flutter/material.dart';

class SingleBar extends StatelessWidget {
  final double height;
  final Color color;
  final double width;

  const SingleBar({
    super.key,
    required this.height,
    required this.color,
    this.width = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.3)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }
}
