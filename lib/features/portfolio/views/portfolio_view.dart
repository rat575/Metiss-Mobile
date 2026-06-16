import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/portfolio_provider.dart';
import 'widgets/energy_bar_chart.dart';
import 'widgets/systems_added_chart.dart';
import 'widgets/performance_ratio_chart.dart';
import 'widgets/zero_production_chart.dart';
import 'widgets/portfolio_accordion.dart';
import 'widgets/metric_cards.dart';
import 'widgets/metric_tab.dart';
import 'widgets/portfolio_filters.dart';
import 'widgets/non_comms_list.dart';

class PortfolioView extends ConsumerStatefulWidget {
  const PortfolioView({super.key});

  @override
  ConsumerState<PortfolioView> createState() => _PortfolioViewState();
}

class _PortfolioViewState extends ConsumerState<PortfolioView> {
  bool _portfolioExpanded = true;
  bool _performanceExpanded = true;
  String _selectedPerformanceMetric = 'Systems Added';

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(portfolioMetricsProvider);
    final graphAsync = ref.watch(portfolioGraphProvider);
    final dateRange = ref.watch(portfolioDateRangeProvider);
    final currentPreset = ref.watch(portfolioDatePresetProvider);
    final chartOptions = ref.watch(portfolioChartOptionsProvider);
    final filterOptionsAsync = ref.watch(portfolioFiltersOptionsProvider);
    final selectedMarkets = ref.watch(selectedMarketsProvider);
    final selectedInstalledBy = ref.watch(selectedInstalledByProvider);
    final selectedInverterManufacturers = ref.watch(
      selectedInverterManufacturersProvider,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Metrics Accordion
          PortfolioAccordion(
            title: 'Portfolio Metrics',
            color: const Color(0xFF00C49C),
            isExpanded: _portfolioExpanded,
            onTap: () =>
                setState(() => _portfolioExpanded = !_portfolioExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Column(
                children: [
                  // Solar Generation Stats Container
                  metricsAsync.when(
                    data: (metrics) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F8F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00C49C)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your solar systems generated:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Column(
                            children: [
                              MetricCard(
                                value: _formatValue(metrics.yesterday),
                                label: 'Yesterday',
                              ),
                              const SizedBox(height: 16),
                              MetricCard(
                                value: _formatValue(metrics.last30Days),
                                label: 'Last 30 Days',
                              ),
                              const SizedBox(height: 16),
                              MetricCard(
                                value: _formatValue(metrics.allTime),
                                label: 'All Time',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(height: 1, color: const Color(0xFFFFB000)),
                          const SizedBox(height: 24),
                          const Text(
                            'CO₂ emissions prevented:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              ImpactCard(
                                icon: LucideIcons.housePlug,
                                value: _formatNumber(metrics.homesPowered),
                                label: 'Homes Powered',
                              ),
                              const SizedBox(height: 12),
                              ImpactCard(
                                icon: LucideIcons.trees,
                                value: _formatNumber(metrics.treeSeedlings),
                                label: 'Trees Planted',
                              ),
                              const SizedBox(height: 12),
                              ImpactCard(
                                icon: LucideIcons.carFront,
                                value: _formatNumber(metrics.carsOffRoad),
                                label: 'Cars Off Road',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF00C49C),
                        ),
                      ),
                    ),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                  const SizedBox(height: 24),

                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        DateFilterBadge(
                          label: currentPreset == PortfolioDatePreset.custom
                              ? '${DateFormat('MMM d, y').format(dateRange.start)} - ${DateFormat('MMM d, y').format(dateRange.end)}'
                              : currentPreset.label,
                          isActive: true,
                          onTap: () => showDatePresetFilterSheet(
                            context: context,
                            ref: ref,
                            presetProvider: portfolioDatePresetProvider,
                            rangeProvider: portfolioDateRangeProvider,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterBadge(
                          label: 'Market',
                          selectedItems: selectedMarkets,
                          onTap: () => showMultiSelectFilterSheet(
                            context: context,
                            title: 'Select Market',
                            options: filterOptionsAsync.value?.markets ?? [],
                            selectedItems: selectedMarkets,
                            provider: selectedMarketsProvider,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterBadge(
                          label: 'Installed By',
                          selectedItems: selectedInstalledBy,
                          onTap: () => showMultiSelectFilterSheet(
                            context: context,
                            title: 'Select Installer',
                            options:
                                filterOptionsAsync.value?.installedBy ?? [],
                            selectedItems: selectedInstalledBy,
                            provider: selectedInstalledByProvider,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterBadge(
                          label: 'Inverter',
                          selectedItems: selectedInverterManufacturers,
                          onTap: () => showMultiSelectFilterSheet(
                            context: context,
                            title: 'Select Inverter',
                            options:
                                filterOptionsAsync
                                    .value
                                    ?.inverterManufacturers ??
                                [],
                            selectedItems: selectedInverterManufacturers,
                            provider: selectedInverterManufacturersProvider,
                          ),
                        ),
                        //clear Button
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(portfolioDatePresetProvider.notifier)
                                  .state = PortfolioDatePreset
                                  .last12Months;
                              ref.read(selectedMarketsProvider.notifier).state =
                                  [];
                              ref
                                      .read(
                                        selectedInstalledByProvider.notifier,
                                      )
                                      .state =
                                  [];
                              ref
                                      .read(
                                        selectedInverterManufacturersProvider
                                            .notifier,
                                      )
                                      .state =
                                  [];
                            },
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text(
                              'Clear all',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF44336),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bar Chart
                  graphAsync.when(
                    data: (data) => EnergyBarChart(
                      data: data,
                      granularity: getGranularity(dateRange),
                      showAverage: chartOptions.showAverage,
                      showContracted: chartOptions.showContracted,
                    ),
                    loading: () => const SizedBox(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00C49C),
                        ),
                      ),
                    ),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Performance Metrics Accordion
          PortfolioAccordion(
            title: 'Performance Metrics',
            color: const Color(0xFFFFB000),
            isExpanded: _performanceExpanded,
            onTap: () =>
                setState(() => _performanceExpanded = !_performanceExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(color: Color(0xFFFFFAE5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        MetricTab(
                          label: 'Systems Added',
                          isActive:
                              _selectedPerformanceMetric == 'Systems Added',
                          onTap: () => setState(
                            () => _selectedPerformanceMetric = 'Systems Added',
                          ),
                        ),
                        const SizedBox(width: 8),
                        MetricTab(
                          label: 'Performance Ratio',
                          isActive:
                              _selectedPerformanceMetric == 'Performance Ratio',
                          onTap: () => setState(
                            () => _selectedPerformanceMetric =
                                'Performance Ratio',
                          ),
                        ),
                        const SizedBox(width: 8),
                        MetricTab(
                          label: 'Non-Comms',
                          isActive: _selectedPerformanceMetric == 'Non-Comms',
                          onTap: () => setState(
                            () => _selectedPerformanceMetric = 'Non-Comms',
                          ),
                        ),
                        const SizedBox(width: 8),
                        MetricTab(
                          label: 'Zero Production',
                          isActive:
                              _selectedPerformanceMetric == 'Zero Production',
                          onTap: () => setState(
                            () =>
                                _selectedPerformanceMetric = 'Zero Production',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedPerformanceMetric == 'Systems Added')
                    Consumer(
                      builder: (context, ref, child) {
                        final systemsData = ref.watch(systemsSummaryProvider);
                        final dateRange = ref.watch(
                          performanceDateRangeProvider,
                        );
                        final currentPreset = ref.watch(
                          performanceDatePresetProvider,
                        );
                        final options = ref.watch(systemsChartOptionsProvider);
                        final filterOptionsAsync = ref.watch(
                          portfolioFiltersOptionsProvider,
                        );
                        final selectedMarkets = ref.watch(
                          performanceSelectedMarketsProvider,
                        );
                        final selectedInstalledBy = ref.watch(
                          performanceSelectedInstalledByProvider,
                        );
                        final selectedInverterManufacturers = ref.watch(
                          performanceSelectedInverterManufacturersProvider,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Performance Filters Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  DateFilterBadge(
                                    label:
                                        currentPreset ==
                                            PortfolioDatePreset.custom
                                        ? '${DateFormat('MMM d, y').format(dateRange.start)} - ${DateFormat('MMM d, y').format(dateRange.end)}'
                                        : currentPreset.label,
                                    isActive: true,
                                    onTap: () => showDatePresetFilterSheet(
                                      context: context,
                                      ref: ref,
                                      presetProvider:
                                          performanceDatePresetProvider,
                                      rangeProvider:
                                          performanceDateRangeProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Market',
                                    selectedItems: selectedMarkets,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Market',
                                      options:
                                          filterOptionsAsync.value?.markets ??
                                          [],
                                      selectedItems: selectedMarkets,
                                      provider:
                                          performanceSelectedMarketsProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Installed By',
                                    selectedItems: selectedInstalledBy,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Installer',
                                      options:
                                          filterOptionsAsync
                                              .value
                                              ?.installedBy ??
                                          [],
                                      selectedItems: selectedInstalledBy,
                                      provider:
                                          performanceSelectedInstalledByProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Inverter',
                                    selectedItems:
                                        selectedInverterManufacturers,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Inverter',
                                      options:
                                          filterOptionsAsync
                                              .value
                                              ?.inverterManufacturers ??
                                          [],
                                      selectedItems:
                                          selectedInverterManufacturers,
                                      provider:
                                          performanceSelectedInverterManufacturersProvider,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        ref
                                                .read(
                                                  performanceSelectedMarketsProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                        ref
                                                .read(
                                                  performanceSelectedInstalledByProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                        ref
                                                .read(
                                                  performanceSelectedInverterManufacturersProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                      },
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Clear all',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFF44336),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            systemsData.when(
                              data: (data) => SystemsAddedChart(
                                data: data,
                                granularity: getGranularity(dateRange),
                                showSystems: options.showSystems,
                                showAverage: options.showAverage,
                                showCumulative: options.showCumulative,
                              ),
                              loading: () => const SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (err, stack) => SizedBox(
                                height: 200,
                                child: Center(child: Text('Error: $err')),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else if (_selectedPerformanceMetric == 'Performance Ratio' ||
                      _selectedPerformanceMetric == 'Zero Production')
                    Consumer(
                      builder: (context, ref, child) {
                        final ratioData = ref.watch(performanceRatioProvider);
                        final dateRange = ref.watch(
                          performanceDateRangeProvider,
                        );
                        final currentPreset = ref.watch(
                          performanceDatePresetProvider,
                        );
                        final filterOptionsAsync = ref.watch(
                          portfolioFiltersOptionsProvider,
                        );
                        final selectedMarkets = ref.watch(
                          performanceSelectedMarketsProvider,
                        );
                        final selectedInstalledBy = ref.watch(
                          performanceSelectedInstalledByProvider,
                        );
                        final selectedInverterManufacturers = ref.watch(
                          performanceSelectedInverterManufacturersProvider,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Performance Filters Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  DateFilterBadge(
                                    label:
                                        currentPreset ==
                                            PortfolioDatePreset.custom
                                        ? '${DateFormat('MMM d, y').format(dateRange.start)} - ${DateFormat('MMM d, y').format(dateRange.end)}'
                                        : currentPreset.label,
                                    isActive: true,
                                    onTap: () => showDatePresetFilterSheet(
                                      context: context,
                                      ref: ref,
                                      presetProvider:
                                          performanceDatePresetProvider,
                                      rangeProvider:
                                          performanceDateRangeProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Market',
                                    selectedItems: selectedMarkets,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Market',
                                      options:
                                          filterOptionsAsync.value?.markets ??
                                          [],
                                      selectedItems: selectedMarkets,
                                      provider:
                                          performanceSelectedMarketsProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Installed By',
                                    selectedItems: selectedInstalledBy,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Installer',
                                      options:
                                          filterOptionsAsync
                                              .value
                                              ?.installedBy ??
                                          [],
                                      selectedItems: selectedInstalledBy,
                                      provider:
                                          performanceSelectedInstalledByProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Inverter',
                                    selectedItems:
                                        selectedInverterManufacturers,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Inverter',
                                      options:
                                          filterOptionsAsync
                                              .value
                                              ?.inverterManufacturers ??
                                          [],
                                      selectedItems:
                                          selectedInverterManufacturers,
                                      provider:
                                          performanceSelectedInverterManufacturersProvider,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        ref
                                                .read(
                                                  performanceSelectedMarketsProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                        ref
                                                .read(
                                                  performanceSelectedInstalledByProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                        ref
                                                .read(
                                                  performanceSelectedInverterManufacturersProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                      },
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Clear all',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFF44336),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedPerformanceMetric ==
                                'Performance Ratio')
                              ratioData.when(
                                data: (data) => PerformanceRatioChart(
                                  data: data,
                                  granularity: getGranularity(dateRange),
                                  dateRange: dateRange,
                                ),
                                loading: () => const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (err, stack) => SizedBox(
                                  height: 200,
                                  child: Center(child: Text('Error: $err')),
                                ),
                              )
                            else if (_selectedPerformanceMetric ==
                                'Zero Production')
                              ref
                                  .watch(zeroProductionProvider)
                                  .when(
                                    data: (data) => ZeroProductionChart(
                                      data: data,
                                      granularity: getGranularity(dateRange),
                                      dateRange: dateRange,
                                    ),
                                    loading: () => const SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    error: (err, stack) => SizedBox(
                                      height: 200,
                                      child: Center(child: Text('Error: $err')),
                                    ),
                                  ),
                          ],
                        );
                      },
                    )
                  else if (_selectedPerformanceMetric == 'Non-Comms')
                    Consumer(
                      builder: (context, ref, child) {
                        final dateRange = ref.watch(
                          performanceDateRangeProvider,
                        );
                        final currentPreset = ref.watch(
                          performanceDatePresetProvider,
                        );
                        final filterOptionsAsync = ref.watch(
                          portfolioFiltersOptionsProvider,
                        );
                        final selectedMarkets = ref.watch(
                          performanceSelectedMarketsProvider,
                        );
                        final selectedInstalledBy = ref.watch(
                          performanceSelectedInstalledByProvider,
                        );
                        final selectedInverterManufacturers = ref.watch(
                          performanceSelectedInverterManufacturersProvider,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Performance Filters Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  DateFilterBadge(
                                    label:
                                        currentPreset ==
                                            PortfolioDatePreset.custom
                                        ? '${DateFormat('MMM d, y').format(dateRange.start)} - ${DateFormat('MMM d, y').format(dateRange.end)}'
                                        : currentPreset.label,
                                    isActive: true,
                                    onTap: () => showDatePresetFilterSheet(
                                      context: context,
                                      ref: ref,
                                      presetProvider:
                                          performanceDatePresetProvider,
                                      rangeProvider:
                                          performanceDateRangeProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Market',
                                    selectedItems: selectedMarkets,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Market',
                                      options:
                                          filterOptionsAsync.value?.markets ??
                                          [],
                                      selectedItems: selectedMarkets,
                                      provider:
                                          performanceSelectedMarketsProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Installed By',
                                    selectedItems: selectedInstalledBy,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Installer',
                                      options:
                                          filterOptionsAsync
                                              .value
                                              ?.installedBy ??
                                          [],
                                      selectedItems: selectedInstalledBy,
                                      provider:
                                          performanceSelectedInstalledByProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterBadge(
                                    label: 'Inverter',
                                    selectedItems:
                                        selectedInverterManufacturers,
                                    onTap: () => showMultiSelectFilterSheet(
                                      context: context,
                                      title: 'Select Inverter',
                                      options:
                                          filterOptionsAsync
                                              .value
                                              ?.inverterManufacturers ??
                                          [],
                                      selectedItems:
                                          selectedInverterManufacturers,
                                      provider:
                                          performanceSelectedInverterManufacturersProvider,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        ref
                                                .read(
                                                  performanceSelectedMarketsProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                        ref
                                                .read(
                                                  performanceSelectedInstalledByProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                        ref
                                                .read(
                                                  performanceSelectedInverterManufacturersProvider
                                                      .notifier,
                                                )
                                                .state =
                                            [];
                                      },
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Clear all',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFF44336),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const NonCommsList(),
                          ],
                        );
                      },
                    )
                  else
                    // Chart placeholder for other metrics
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDAE3E1)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 48,
                              color: Color(0xFFDAE3E1),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Chart data will appear here',
                              style: TextStyle(
                                color: Color(0xFF889492),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatValue(double wh) {
    final abs = wh.abs();
    if (abs >= 1000000000000) {
      return '${(wh / 1000000000000).toStringAsFixed(2)} TWh';
    }
    if (abs >= 1000000000) {
      return '${(wh / 1000000000).toStringAsFixed(2)} GWh';
    }
    if (abs >= 1000000) {
      return '${(wh / 1000000).toStringAsFixed(2)} MWh';
    }
    if (abs >= 1000) {
      return '${(wh / 1000).toStringAsFixed(2)} kWh';
    }
    return '${wh.toStringAsFixed(2)} kWh';
  }

  String _formatNumber(double value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(0);
  }
}
