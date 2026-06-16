import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/portfolio/models/portfolio_entities.dart';
import '../../viewmodels/portfolio_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'portfolio_legend_item.dart';
import 'single_bar.dart';
import 'chart_utils.dart';

class EnergyBarChart extends StatelessWidget {
  final List<EnergyDataPointEntity> data;
  final String granularity;
  final bool showAverage;
  final bool showContracted;

  const EnergyBarChart({
    super.key,
    required this.data,
    required this.granularity,
    this.showAverage = false,
    this.showContracted = true,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "data: ${data.map((e) => '{date: ${e.date}, totalProductionWh: ${e.totalProductionWh}, contracted: ${e.contractedEnergy}, average: ${e.averageProductionWh}}').toList()}",
    );
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available in this range')),
      );
    }

    // Aggregate data based on granularity to avoid duplicates
    final Map<String, EnergyDataPointEntity> aggregated = {};
    for (final point in data) {
      final date = DateTime.tryParse(point.date) ?? DateTime.now();
      String key;
      if (granularity == 'daily') {
        key = DateFormat('yyyy-MM-dd').format(date);
      } else if (granularity == 'monthly') {
        key = DateFormat('yyyy-MM').format(date);
      } else {
        key = DateFormat('yyyy').format(date);
      }
      if (aggregated.containsKey(key)) {
        final existing = aggregated[key]!;
        aggregated[key] = EnergyDataPointEntity(
          date: existing.date,
          totalProductionWh:
              existing.totalProductionWh + point.totalProductionWh,
          contractedEnergy:
              (existing.contractedEnergy ?? 0) + (point.contractedEnergy ?? 0),
          averageProductionWh: math.max(
            existing.averageProductionWh,
            point.averageProductionWh,
          ),
        );
      } else {
        aggregated[key] = point;
      }
    }
    debugPrint(
      "aggregated: ${aggregated.values.toList().map((e) => '{date: ${e.date}, totalProductionWh: ${e.totalProductionWh}, contracted: ${e.contractedEnergy}, average: ${e.averageProductionWh}}').toList()}",
    );
    final displayData = aggregated.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate dynamic max value
    double maxKWh = displayData.fold<double>(0, (prev, point) {
      final p = point.totalProductionWh / 1000;
      final c = (point.contractedEnergy ?? 0) / 1000;
      return math.max(prev, math.max(p, c));
    });

    if (maxKWh < 1) maxKWh = 1;

    final scale = _getEnergyScale(maxKWh);
    const int tickCount = 7;
    final double step = (maxKWh / (tickCount - 2)).ceilToDouble();
    final double absoluteMax = step * (tickCount - 1);

    final List<String> labels = [];
    for (int i = 0; i < tickCount; i++) {
      final val = (tickCount - 1 - i) * step;
      if (i == tickCount - 1) {
        labels.add(scale['unit'] as String);
      } else {
        final scaledVal = val / (scale['divisor'] as double);
        labels.add(scaledVal.toStringAsFixed(1));
      }
    }

    const double topPadding = 20.0;
    const double bottomPadding = 40.0;
    const double chartHeight = 190.0;
    const double totalHeight = topPadding + bottomPadding + chartHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Consumer(
          builder: (context, ref, child) {
            final options = ref.watch(portfolioChartOptionsProvider);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const PortfolioLegendItem(
                    color: Color(0xFF00A3E0),
                    label: 'Energy Produced',
                  ),
                  const SizedBox(width: 16),
                  PortfolioLegendItem(
                    color: AppTheme.secondaryColor,
                    label: 'Contracted Energy',
                    value: options.showContracted,
                    onChanged: (val) {
                      ref.read(portfolioChartOptionsProvider.notifier).state =
                          options.copyWith(showContracted: val ?? false);
                    },
                  ),
                  const SizedBox(width: 16),
                  PortfolioLegendItem(
                    color: const Color(0xFFA64DFF),
                    label: 'Ave. Energy Produced',
                    isHollow: true,
                    value: options.showAverage,
                    onChanged: (val) {
                      ref.read(portfolioChartOptionsProvider.notifier).state =
                          options.copyWith(showAverage: val ?? false);
                    },
                  ),
                  const SizedBox(width: 16),
                  const PortfolioLegendItem(
                    color: Color(0xFFCACECE),
                    label: 'Weather Adjusted Future Release',
                    isHollow: true,
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
              // Y-Axis Labels
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

              // Scrollable Chart Content
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      // Horizontal Grid Lines
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
                                (point) => _BarGroup(
                                  point: point,
                                  maxKWh: absoluteMax,
                                  granularity: granularity,
                                  showContracted: showContracted,
                                  unit: scale['unit'] as String,
                                  divisor: scale['divisor'] as double,
                                  chartHeight: chartHeight,
                                  bottomPadding: bottomPadding,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      // Average Line
                      if (showAverage && displayData.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final totalWh = displayData.fold<double>(
                              0,
                              (prev, p) => prev + p.totalProductionWh,
                            );
                            final avgWh = totalWh / displayData.length;
                            final avgKWh = avgWh / 1000; // Convert Wh to kWh
                            final double lineY =
                                (avgKWh / absoluteMax).clamp(0.0, 1.0) *
                                chartHeight;

                            return Positioned(
                              bottom: bottomPadding + lineY,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFA64DFF),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x4DA64DFF),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

  Map<String, dynamic> _getEnergyScale(double maxKWh) {
    if (maxKWh >= 1000000000) {
      return {'unit': 'TWh', 'divisor': 1000000000.0};
    }
    if (maxKWh >= 1000000) {
      return {'unit': 'GWh', 'divisor': 1000000.0};
    }
    if (maxKWh >= 1000) {
      return {'unit': 'MWh', 'divisor': 1000.0};
    }
    return {'unit': 'kWh', 'divisor': 1.0};
  }
}

class _BarGroup extends StatelessWidget {
  final EnergyDataPointEntity point;
  final double maxKWh;
  final String granularity;
  final String unit;
  final double divisor;
  final bool showContracted;
  final double chartHeight;
  final double bottomPadding;

  const _BarGroup({
    required this.point,
    required this.maxKWh,
    required this.granularity,
    required this.unit,
    required this.divisor,
    required this.chartHeight,
    required this.bottomPadding,
    this.showContracted = true,
  });

  @override
  Widget build(BuildContext context) {
    // Scale values (production is in Wh, convert to kWh)
    final productionKWh = point.totalProductionWh / 1000;
    final contractedKWh = (point.contractedEnergy ?? 0) / 1000;

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
            'Energy Produced: ',
            _formatScaledEnergy(point.totalProductionWh),
            const Color(0xFF00A3E0),
          ),
          if (point.contractedEnergy != null) ...[
            const TextSpan(text: '\n'),
            buildTooltipRow(
              'Contracted: ',
              _formatScaledEnergy(point.contractedEnergy!),
              const Color(0xFFFDB913),
            ),
          ],
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showContracted && point.contractedEnergy != null) ...[
                  SingleBar(
                    height:
                        (contractedKWh / maxKWh).clamp(0.01, 1.0) * chartHeight,
                    color: const Color(0xFFFDB913),
                  ),
                  const SizedBox(width: 4),
                ],
                SingleBar(
                  height:
                      (productionKWh / maxKWh).clamp(0.01, 1.0) * chartHeight,
                  color: const Color(0xFF00A3E0),
                ),
              ],
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

  String _formatScaledEnergy(double wh) {
    final kWh = wh / 1000;
    final scaled = kWh / divisor;
    return '${scaled.toStringAsFixed(2)} $unit';
  }
}
