import 'package:flutter/material.dart';

class PortfolioLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isHollow;
  final bool? value;
  final ValueChanged<bool?>? onChanged;

  const PortfolioLegendItem({
    super.key,
    required this.color,
    required this.label,
    this.isHollow = false,
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!(value ?? false)) : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null) ...[
              SizedBox(
                child: Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: value == true ? color : Colors.transparent,
                    border: Border.all(color: color, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isHollow ? Colors.transparent : color,
                  border: isHollow
                      ? Border.all(color: color, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF01372C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
