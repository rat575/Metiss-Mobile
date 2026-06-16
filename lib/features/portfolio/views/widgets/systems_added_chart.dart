import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/portfolio_entities.dart';
import '../../viewmodels/portfolio_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'portfolio_legend_item.dart';
import 'chart_utils.dart';

class SystemsAddedChart extends StatelessWidget {
  final List<SystemsDataPointEntity> data;
  final String granularity;
  final bool showSystems;
  final bool showAverage;
  final bool showCumulative;

  const SystemsAddedChart({
    super.key,
    required this.data,
    required this.granularity,
    this.showSystems = true,
    this.showAverage = false,
    this.showCumulative = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available in this range')),
      );
    }

    final displayData = List<SystemsDataPointEntity>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate max for left axis (systems and average)
    double maxLeft = displayData.fold<double>(0, (prev, p) {
      return math.max(prev, math.max(p.newSystems, p.average ?? 0));
    });
    if (maxLeft < 1) maxLeft = 1;

    // Calculate max for right axis (cumulative)
    double maxRight = displayData.fold<double>(0, (prev, p) {
      return math.max(prev, p.cumulativeSystems ?? 0);
    });
    if (maxRight < 1) maxRight = 1;

    const int tickCount = 7;
    final double stepLeft = (maxLeft / (tickCount - 2)).ceilToDouble();
    final double absoluteMaxLeft = stepLeft * (tickCount - 1);

    final double stepRight = (maxRight / (tickCount - 2)).ceilToDouble();
    final double absoluteMaxRight = stepRight * (tickCount - 1);

    final List<String> leftLabels = [];
    final List<String> rightLabels = [];
    for (int i = 0; i < tickCount; i++) {
      final valL = (tickCount - 1 - i) * stepLeft;
      leftLabels.add(valL.toInt().toString());

      final valR = (tickCount - 1 - i) * stepRight;
      rightLabels.add(valR.toInt().toString());
    }

    const double topPadding = 20.0;
    const double bottomPadding = 40.0;
    const double chartHeight = 220.0;
    const double totalHeight = topPadding + bottomPadding + chartHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Consumer(
          builder: (context, ref, child) {
            final options = ref.watch(systemsChartOptionsProvider);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PortfolioLegendItem(
                    color: const Color(0xFF009AE0),
                    label: 'Systems added',
                    value: options.showSystems,
                    onChanged: (val) {
                      ref.read(systemsChartOptionsProvider.notifier).state =
                          options.copyWith(showSystems: val ?? false);
                    },
                  ),
                  const SizedBox(width: 16),
                  PortfolioLegendItem(
                    color: const Color(0xFFFEB100),
                    label: 'Ave. # added',
                    isHollow: true,
                    value: options.showAverage,
                    onChanged: (val) {
                      ref.read(systemsChartOptionsProvider.notifier).state =
                          options.copyWith(showAverage: val ?? false);
                    },
                  ),
                  const SizedBox(width: 16),
                  PortfolioLegendItem(
                    color: const Color(0xFFA535CE),
                    label: 'Cumulative',
                    isHollow: true,
                    value: options.showCumulative,
                    onChanged: (val) {
                      ref.read(systemsChartOptionsProvider.notifier).state =
                          options.copyWith(showCumulative: val ?? false);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Chart Area
        SizedBox(
          height: totalHeight,
          child: Row(
            children: [
              // Left Y-Axis
              Padding(
                padding: const EdgeInsets.only(
                  top: topPadding,
                  bottom: bottomPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: leftLabels
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

              // Scrollable Chart Content
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                              width: displayData.length * 60.0 + 40,
                              height: 0.5,
                              color: const Color(0xFFE5E8E7),
                            ),
                          ),
                        ),
                      ),
                      // Bars
                      Padding(
                        padding: const EdgeInsets.only(
                          top: topPadding,
                          bottom: 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: displayData
                              .map(
                                (p) => _SystemBarGroup(
                                  point: p,
                                  maxVal: absoluteMaxLeft,
                                  granularity: granularity,
                                  showSystems: showSystems,
                                  chartHeight: chartHeight,
                                  bottomPadding: bottomPadding,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      // Line Graphs
                      if (showAverage || showCumulative)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SystemsLinePainter(
                              data: displayData,
                              maxValL: absoluteMaxLeft,
                              maxValR: absoluteMaxRight,
                              showAverage: showAverage,
                              showCumulative: showCumulative,
                              chartHeight: chartHeight,
                              topPadding: topPadding,
                              bottomPadding: bottomPadding,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (showCumulative) ...[
                const SizedBox(width: 8),
                // Right Y-Axis
                Padding(
                  padding: const EdgeInsets.only(
                    top: topPadding,
                    bottom: bottomPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: rightLabels
                        .map(
                          (label) => Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFA535CE),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SystemBarGroup extends StatelessWidget {
  final SystemsDataPointEntity point;
  final double maxVal;
  final String granularity;
  final bool showSystems;
  final double chartHeight;
  final double bottomPadding;

  const _SystemBarGroup({
    required this.point,
    required this.maxVal,
    required this.granularity,
    required this.showSystems,
    required this.chartHeight,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          TextSpan(
            text: '${formatFullDate(point.date)}\n',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              fontSize: 12,
            ),
          ),
          const TextSpan(text: '\n'),
          buildTooltipRow(
            'Systems Added: ',
            point.newSystems.toInt().toString(),
            const Color(0xFF009AE0),
          ),
          if (point.average != null) ...[
            const TextSpan(text: '\n'),
            buildTooltipRow(
              'Average: ',
              point.average!.toStringAsFixed(2),
              const Color(0xFFFEB100),
            ),
          ],
          if (point.cumulativeSystems != null) ...[
            const TextSpan(text: '\n'),
            buildTooltipRow(
              'Cumulative: ',
              point.cumulativeSystems!.toInt().toString(),
              const Color(0xFFA535CE),
            ),
          ],
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showSystems)
              Container(
                width: 30,
                height:
                    (point.newSystems / maxVal).clamp(0.01, 1.0) * chartHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF009AE0),
                      const Color(0xFF009AE0).withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            const SizedBox(height: 10), // Gap to baseline (40 - 20 - 10 = 10)
            SizedBox(
              height: 20, // fixed height for date text
              child: Text(
                formatChartDate(point.date, granularity),
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF889492),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10), // Bottom buffer
          ],
        ),
      ),
    );
  }
}

class _SystemsLinePainter extends CustomPainter {
  final List<SystemsDataPointEntity> data;
  final double maxValL;
  final double maxValR;
  final bool showAverage;
  final bool showCumulative;
  final double chartHeight;
  final double topPadding;
  final double bottomPadding;

  _SystemsLinePainter({
    required this.data,
    required this.maxValL,
    required this.maxValR,
    required this.showAverage,
    required this.showCumulative,
    required this.chartHeight,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    if (showAverage) {
      _drawLine(
        canvas,
        size,
        const Color(0xFFFEB100),
        (p) => p.average ?? 0,
        maxValL,
        2.0,
      );
    }

    if (showCumulative) {
      _drawLine(
        canvas,
        size,
        const Color(0xFFA535CE),
        (p) => p.cumulativeSystems ?? 0,
        maxValR,
        3.0,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    Color color,
    double Function(SystemsDataPointEntity) getValue,
    double max,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    bool started = false;

    for (int i = 0; i < data.length; i++) {
      final val = getValue(data[i]);
      // Match the spacing in _SystemBarGroup (width 30 + some gap)
      // The bars are centered in a 60px slot
      final double x = 30.0 + (i * 60.0);
      final double y =
          size.height -
          bottomPadding -
          (val / max).clamp(0.0, 1.0) * chartHeight;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SystemsLinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.showAverage != showAverage ||
        oldDelegate.showCumulative != showCumulative;
  }
}
