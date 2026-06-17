import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/portfolio_entities.dart';
import '../../../../core/theme/app_theme.dart';
import 'chart_utils.dart';

class _AggregatedPoint {
  final double actualWh;
  final double expectedWh;
  final int count;

  _AggregatedPoint({
    required this.actualWh,
    required this.expectedWh,
    required this.count,
  });
}

class _ChartDisplayPoint {
  final String dateStr;
  final String label;
  final double performanceRatio;
  final double actualWh;
  final double expectedWh;
  final bool hasData;
  final double adjustedValue;

  _ChartDisplayPoint({
    required this.dateStr,
    required this.label,
    required this.performanceRatio,
    required this.actualWh,
    required this.expectedWh,
    required this.hasData,
    required this.adjustedValue,
  });
}

class PerformanceRatioChart extends StatelessWidget {
  final List<PerformanceRatioDataPointEntity> data;
  final String granularity;
  final DateTimeRange dateRange;

  const PerformanceRatioChart({
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
          aggMap[key] ?? _AggregatedPoint(actualWh: 0, expectedWh: 0, count: 0);
      aggMap[key] = _AggregatedPoint(
        actualWh: existing.actualWh + item.actualWh,
        expectedWh: existing.expectedWh + item.totalExpectedWh,
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
            performanceRatio: 1.0,
            actualWh: 0,
            expectedWh: 0,
            hasData: false,
            adjustedValue: 0.0,
          ),
        );
        continue;
      }

      // Calculate the true weighted performance ratio client-side
      final double pr = agg.expectedWh != 0
          ? agg.actualWh / agg.expectedWh
          : 0.0;
      double adjustedValue = pr - 1.0;

      const double epsilon = 0.01;
      if (adjustedValue.abs() < epsilon && pr > 0.0) {
        adjustedValue = adjustedValue >= 0 ? epsilon : -epsilon;
      }

      displayPoints.add(
        _ChartDisplayPoint(
          dateStr: slot.toIso8601String(),
          label: label,
          performanceRatio: pr,
          actualWh: agg.actualWh,
          expectedWh: agg.expectedWh,
          hasData: pr > 0,
          adjustedValue: adjustedValue,
        ),
      );
    }

    // 5. Calculate symmetric Y-axis limits using valid deviations
    final double maxDeviation = displayPoints
        .where((p) => p.hasData)
        .fold<double>(0.1, (prev, p) {
          return math.max(prev, p.adjustedValue.abs());
        });

    const int stepsPerSide = 3;
    double step =
        ((maxDeviation / (stepsPerSide - 1)) * 10).ceilToDouble() / 10;
    if (step < 0.1) step = 0.1;
    final double axisLimit = stepsPerSide * step;

    // Generate Y-axis tick labels (from high to low)
    final List<String> labels = [];
    const int totalTicks = stepsPerSide * 2 + 1;
    for (int i = 0; i < totalTicks; i++) {
      final double val = (stepsPerSide - i) * step;
      final double displayVal = 1.0 + val;
      labels.add(displayVal.toStringAsFixed(1));
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
                          style: TextStyle(
                            fontSize: 10,
                            color: label == '1.0'
                                ? const Color(0xFF01372C)
                                : const Color(0xFF889492),
                            fontWeight: label == '1.0'
                                ? FontWeight.w800
                                : FontWeight.w500,
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
                      // Grid Lines (and bold center baseline)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: topPadding,
                          bottom: bottomPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(totalTicks, (index) {
                            final isBaseline = index == stepsPerSide;
                            return Container(
                              width: displayPoints.length * 60.0 + 40,
                              height: isBaseline ? 1.5 : 0.5,
                              color: isBaseline
                                  ? const Color(0xFF889492)
                                  : const Color(0xFFE5E8E7),
                            );
                          }),
                        ),
                      ),

                      // Deviation Bar Columns
                      Padding(
                        padding: const EdgeInsets.only(
                          top: topPadding,
                          bottom: 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: displayPoints
                              .map(
                                (p) => _PerformanceBarGroup(
                                  point: p,
                                  axisLimit: axisLimit,
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

class _PerformanceBarGroup extends StatelessWidget {
  final _ChartDisplayPoint point;
  final double axisLimit;
  final String granularity;
  final double chartHeight;
  final double bottomPadding;

  const _PerformanceBarGroup({
    required this.point,
    required this.axisLimit,
    required this.granularity,
    required this.chartHeight,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final double halfHeight = chartHeight / 2;
    final double barHeight =
        (point.adjustedValue.abs() / axisLimit).clamp(0.01, 1.0) * halfHeight;

    final isAbove = point.adjustedValue >= 0;

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
                  'Actual Energy: ',
                  '${NumberFormat('#,##0').format(point.actualWh)} Wh',
                  const Color(0xFF01372C),
                ),
                const TextSpan(text: '\n'),
                buildTooltipRow(
                  'Expected Energy: ',
                  '${NumberFormat('#,##0').format(point.expectedWh)} Wh',
                  const Color(0xFF889492),
                ),
                const TextSpan(text: '\n'),
                buildTooltipRow(
                  'Performance Ratio: ',
                  point.performanceRatio.toStringAsFixed(2),
                  isAbove ? const Color(0xFF00C49C) : const Color(0xFFE8615A),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Double-sided deviation bar column
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
                  : isAbove
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(height: halfHeight - barHeight),
                        Container(
                          width: 30,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF00C49C),
                                const Color(0xFF00C49C).withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        SizedBox(height: halfHeight),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: halfHeight),
                        Container(
                          width: 30,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFE8615A).withValues(alpha: 0.3),
                                const Color(0xFFE8615A),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(4),
                            ),
                          ),
                        ),
                        SizedBox(height: halfHeight - barHeight),
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
