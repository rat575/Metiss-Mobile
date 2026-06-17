import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/portfolio_entities.dart';
import '../../../../core/theme/app_theme.dart';
import 'chart_utils.dart';

class _AggregatedPoint {
  final double zeroProductionSystems;
  final double totalSystems;
  final int count;

  _AggregatedPoint({
    required this.zeroProductionSystems,
    required this.totalSystems,
    required this.count,
  });
}

class _ChartDisplayPoint {
  final String dateStr;
  final String label;
  final double zeroProductionSystems;
  final double totalSystems;
  final bool hasData;

  _ChartDisplayPoint({
    required this.dateStr,
    required this.label,
    required this.zeroProductionSystems,
    required this.totalSystems,
    required this.hasData,
  });
}

class ZeroProductionChart extends StatelessWidget {
  final List<ZeroProductionDataPointEntity> data;
  final String granularity;
  final DateTimeRange dateRange;

  const ZeroProductionChart({
    super.key,
    required this.data,
    required this.granularity,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Establish start and end dates
    final startDate = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    );
    final endDate = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      23,
      59,
      59,
      999,
    );

    // 2. Generate date slots for exact alignment
    final List<DateTime> dateSlots = [];
    if (granularity == 'daily') {
      var current = startDate;
      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        dateSlots.add(DateTime(current.year, current.month, current.day));
        current = current.add(const Duration(days: 1));
      }
    } else if (granularity == 'monthly') {
      var current = DateTime(startDate.year, startDate.month, 1);
      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        dateSlots.add(current);
        current = DateTime(current.year, current.month + 1, 1);
      }
    } else {
      var current = DateTime(startDate.year, 1, 1);
      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        dateSlots.add(current);
        current = DateTime(current.year + 1, 1, 1);
      }
    }

    if (dateSlots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No slots available inside range')),
      );
    }

    // 3. Aggregate raw API records into date keys
    final Map<String, _AggregatedPoint> aggMap = {};
    for (final item in data) {
      final d = DateTime.tryParse(item.date);
      if (d == null) continue;

      final localD = DateTime(d.year, d.month, d.day);
      if (localD.isBefore(startDate) || localD.isAfter(endDate)) continue;

      String key;
      if (granularity == 'daily') {
        key = DateFormat('yyyy-MM-dd').format(d);
      } else if (granularity == 'monthly') {
        key = DateFormat('yyyy-MM').format(d);
      } else {
        key = '${d.year}';
      }

      final existing =
          aggMap[key] ??
          _AggregatedPoint(zeroProductionSystems: 0, totalSystems: 0, count: 0);
      aggMap[key] = _AggregatedPoint(
        zeroProductionSystems:
            existing.zeroProductionSystems + item.zeroProductionSystems,
        totalSystems:
            existing.totalSystems +
            (item.totalSystems ?? item.zeroProductionSystems),
        count: existing.count + 1,
      );
    }

    // 4. Map the slots into Display Points
    final List<_ChartDisplayPoint> displayPoints = [];
    for (final slot in dateSlots) {
      String key;
      String label;
      if (granularity == 'daily') {
        key = DateFormat('yyyy-MM-dd').format(slot);
        label = DateFormat('MMM dd').format(slot);
      } else if (granularity == 'monthly') {
        key = DateFormat('yyyy-MM').format(slot);
        label = DateFormat('MMM y').format(slot);
      } else {
        key = '${slot.year}';
        label = '${slot.year}';
      }

      final agg = aggMap[key];
      if (agg == null || agg.count == 0) {
        displayPoints.add(
          _ChartDisplayPoint(
            dateStr: slot.toIso8601String(),
            label: label,
            zeroProductionSystems: 0,
            totalSystems: 0,
            hasData: false,
          ),
        );
        continue;
      }

      displayPoints.add(
        _ChartDisplayPoint(
          dateStr: slot.toIso8601String(),
          label: label,
          zeroProductionSystems: agg.zeroProductionSystems,
          totalSystems: agg.totalSystems,
          hasData: true,
        ),
      );
    }

    // 5. Calculate Y-axis limits
    final double maxVal = displayPoints
        .where((p) => p.hasData)
        .fold<double>(
          1.0,
          (prev, p) => math.max(prev, p.zeroProductionSystems),
        );

    const int tickCount = 7;
    final double step = (maxVal / (tickCount - 2)).ceilToDouble();
    final double absoluteMax = step * (tickCount - 1);

    // Generate Y-axis tick labels
    final List<String> labels = [];
    for (int i = 0; i < tickCount; i++) {
      final val = (tickCount - 1 - i) * step;
      labels.add(NumberFormat('#,##0').format(val));
    }

    const double topPadding = 20.0;
    const double bottomPadding = 40.0;
    const double chartHeight = 220.0;
    const double totalHeight = topPadding + bottomPadding + chartHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactive Scrollable Chart Area
        SizedBox(
          height: totalHeight,
          child: Row(
            children: [
              // Y-Axis Labels Column
              Padding(
                padding: const EdgeInsets.only(
                  top: topPadding,
                  bottom: bottomPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: labels
                      .map(
                        (label) => Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF889492),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),

              // Scrollable Chart Canvas
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      // Grid Lines
                      Padding(
                        padding: const EdgeInsets.only(
                          top: topPadding,
                          bottom: bottomPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            tickCount,
                            (index) => Container(
                              width: displayPoints.length * 60.0 + 40,
                              height: 0.5,
                              color: const Color(0xFFE5E8E7),
                            ),
                          ),
                        ),
                      ),

                      // Bar Columns
                      Padding(
                        padding: const EdgeInsets.only(
                          top: topPadding,
                          bottom: 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: displayPoints
                              .map(
                                (p) => _ZeroProductionBarGroup(
                                  point: p,
                                  maxVal: absoluteMax,
                                  granularity: granularity,
                                  chartHeight: chartHeight,
                                  bottomPadding: bottomPadding,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZeroProductionBarGroup extends StatelessWidget {
  final _ChartDisplayPoint point;
  final double maxVal;
  final String granularity;
  final double chartHeight;
  final double bottomPadding;

  const _ZeroProductionBarGroup({
    required this.point,
    required this.maxVal,
    required this.granularity,
    required this.chartHeight,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final double barHeight =
        (point.zeroProductionSystems / maxVal).clamp(0.0, 1.0) * chartHeight;

    final double zeroPercent = point.totalSystems > 0
        ? (point.zeroProductionSystems / point.totalSystems) * 100
        : 0.0;

    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFDAE3E1)),
      ),
      richMessage: TextSpan(
        children: !point.hasData
            ? [
                TextSpan(
                  text: '${formatFullDate(point.dateStr)}\n',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
                const TextSpan(text: '\n'),
                const TextSpan(
                  text: 'No data available in this range',
                  style: TextStyle(
                    color: Color(0xFF889492),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
            : [
                TextSpan(
                  text: '${formatFullDate(point.dateStr)}\n',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
                const TextSpan(text: '\n'),
                buildTooltipRow(
                  'Systems: ',
                  NumberFormat('#,##0').format(point.totalSystems),
                  const Color(0xFF01372C),
                ),
                const TextSpan(text: '\n'),
                buildTooltipRow(
                  'Zero Production: ',
                  NumberFormat('#,##0').format(point.zeroProductionSystems),
                  const Color(0xFFE8615A),
                ),
                const TextSpan(text: '\n'),
                buildTooltipRow(
                  'Zero Production %: ',
                  '${zeroPercent.toStringAsFixed(2)}%',
                  const Color(0xFFE8615A),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: chartHeight,
              child: !point.hasData
                  ? SizedBox(
                      width: 30,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDAE3E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 30,
                          height: math.max(
                            barHeight,
                            2.0,
                          ), // ensure minimal height is visible if hasData
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFE9C6),
                                Color(0xFFE8615A),
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            // Date label
            SizedBox(
              height: 20,
              child: Text(
                formatChartDate(point.dateStr, granularity),
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF889492),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
