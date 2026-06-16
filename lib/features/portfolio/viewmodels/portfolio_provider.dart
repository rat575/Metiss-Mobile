import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/portfolio/repositories/portfolio_repository_provider.dart';
import '../models/portfolio_entities.dart';

enum PortfolioDatePreset {
  last7Days,
  last30Days,
  last12Months,
  allTime,
  custom,
}

extension PortfolioDatePresetExtension on PortfolioDatePreset {
  String get label {
    switch (this) {
      case PortfolioDatePreset.last7Days:
        return 'Last 7 days';
      case PortfolioDatePreset.last30Days:
        return 'Last 30 days';
      case PortfolioDatePreset.last12Months:
        return 'Last 12 months';
      case PortfolioDatePreset.allTime:
        return 'All Time';
      case PortfolioDatePreset.custom:
        return 'Custom';
    }
  }
}

final portfolioDatePresetProvider = StateProvider<PortfolioDatePreset>(
  (ref) => PortfolioDatePreset.last12Months,
);

class PortfolioDateRangeNotifier extends StateNotifier<DateTimeRange> {
  PortfolioDateRangeNotifier()
    : super(_calculateRange(PortfolioDatePreset.last12Months));

  static DateTimeRange _calculateRange(PortfolioDatePreset preset) {
    final now = DateTime.now(); //year , month , day , hour , minute , second
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final endOfYesterday = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      23,
      59,
      59,
      999,
    );

    switch (preset) {
      case PortfolioDatePreset.last7Days:
        return DateTimeRange(
          start: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day - 6,
            0,
            0,
            0,
          ),
          end: endOfYesterday,
        );
      case PortfolioDatePreset.last30Days:
        return DateTimeRange(
          start: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day - 29,
            0,
            0,
            0,
          ),
          end: endOfYesterday,
        );
      case PortfolioDatePreset.last12Months:
        // Ensures exact 12 months ending yesterday
        final start = DateTime(
          yesterday.year - 1,
          yesterday.month,
          yesterday.day + 1,
          0,
          0,
          0,
        );
        return DateTimeRange(start: start, end: endOfYesterday);
      case PortfolioDatePreset.allTime:
        // Defaulting to 2010 if no monitoring start date is available, matching Vista's fallback
        return DateTimeRange(
          start: DateTime(2010, 1, 1, 0, 0, 0),
          end: endOfYesterday,
        );
      case PortfolioDatePreset.custom:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  void updatePreset(PortfolioDatePreset preset) {
    if (preset != PortfolioDatePreset.custom) {
      state = _calculateRange(preset);
    }
  }

  void setCustomRange(DateTimeRange range) {
    state = range;
  }
}

final portfolioDateRangeProvider =
    StateNotifierProvider<PortfolioDateRangeNotifier, DateTimeRange>((ref) {
      final notifier = PortfolioDateRangeNotifier();

      // Listen to preset changes and update range automatically
      ref.listen(portfolioDatePresetProvider, (previous, next) {
        notifier.updatePreset(next);
      });

      return notifier;
    });

String getGranularity(DateTimeRange range) {
  final days = range.end.difference(range.start).inDays + 1;
  if (days <= 31) return 'daily';
  if (days <= 370) return 'monthly';
  return 'yearly';
}

final portfolioMetricsProvider = FutureProvider<PortfolioMetricsEntity>((
  ref,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPortfolioMetrics();
});

class PortfolioChartOptions {
  final bool showContracted;
  final bool showAverage;

  PortfolioChartOptions({this.showContracted = true, this.showAverage = false});

  PortfolioChartOptions copyWith({bool? showContracted, bool? showAverage}) {
    return PortfolioChartOptions(
      showContracted: showContracted ?? this.showContracted,
      showAverage: showAverage ?? this.showAverage,
    );
  }
}

final portfolioChartOptionsProvider = StateProvider<PortfolioChartOptions>((
  ref,
) {
  return PortfolioChartOptions();
});

// New providers for filter selections
final selectedMarketsProvider = StateProvider<List<String>>((ref) => []);
final selectedInstalledByProvider = StateProvider<List<String>>((ref) => []);
final selectedInverterManufacturersProvider = StateProvider<List<String>>(
  (ref) => [],
);

// Performance filters providers
final performanceDatePresetProvider = StateProvider<PortfolioDatePreset>(
  (ref) => PortfolioDatePreset
      .allTime, // default to allTime matching Vista's default
);

final performanceDateRangeProvider =
    StateNotifierProvider<PortfolioDateRangeNotifier, DateTimeRange>((ref) {
      final notifier = PortfolioDateRangeNotifier();

      // Initialize to allTime for performance metrics
      notifier.updatePreset(PortfolioDatePreset.allTime);

      // Listen to preset changes and update range automatically
      ref.listen(performanceDatePresetProvider, (previous, next) {
        notifier.updatePreset(next);
      });

      return notifier;
    });

final performanceSelectedMarketsProvider = StateProvider<List<String>>(
  (ref) => [],
);
final performanceSelectedInstalledByProvider = StateProvider<List<String>>(
  (ref) => [],
);
final performanceSelectedInverterManufacturersProvider =
    StateProvider<List<String>>((ref) => []);

// New provider for fetching available filter options
final portfolioFiltersOptionsProvider =
    FutureProvider<PortfolioFilterOptionsEntity>((ref) async {
      final repository = ref.watch(portfolioRepositoryProvider);
      return repository.getPortfolioFilters();
    });

final portfolioGraphProvider = FutureProvider<List<EnergyDataPointEntity>>((
  ref,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  final dateRange = ref.watch(portfolioDateRangeProvider);

  // Watch all filters
  final markets = ref.watch(selectedMarketsProvider);
  final installedBy = ref.watch(selectedInstalledByProvider);
  final inverterManufacturers = ref.watch(
    selectedInverterManufacturersProvider,
  );

  return repository.getPortfolioGraphData(
    from: dateRange.start,
    to: dateRange.end,
    granularity: getGranularity(dateRange),
    markets: markets,
    installedBy: installedBy,
    inverterManufacturers: inverterManufacturers,
  );
});

class SystemsChartOptions {
  final bool showSystems;
  final bool showAverage;
  final bool showCumulative;

  SystemsChartOptions({
    this.showSystems = true,
    this.showAverage = false,
    this.showCumulative = false,
  });

  SystemsChartOptions copyWith({
    bool? showSystems,
    bool? showAverage,
    bool? showCumulative,
  }) {
    return SystemsChartOptions(
      showSystems: showSystems ?? this.showSystems,
      showAverage: showAverage ?? this.showAverage,
      showCumulative: showCumulative ?? this.showCumulative,
    );
  }
}

final systemsChartOptionsProvider = StateProvider<SystemsChartOptions>((ref) {
  return SystemsChartOptions();
});

final systemsSummaryProvider = FutureProvider<List<SystemsDataPointEntity>>((
  ref,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  final dateRange = ref.watch(performanceDateRangeProvider);

  // Watch all filters
  final markets = ref.watch(performanceSelectedMarketsProvider);
  final installedBy = ref.watch(performanceSelectedInstalledByProvider);
  final inverterManufacturers = ref.watch(
    performanceSelectedInverterManufacturersProvider,
  );

  return repository.getSystemsSummary(
    from: dateRange.start,
    to: dateRange.end,
    granularity: getGranularity(dateRange),
    markets: markets,
    installedBy: installedBy,
    inverterManufacturers: inverterManufacturers,
  );
});

final performanceRatioProvider =
    FutureProvider<List<PerformanceRatioDataPointEntity>>((ref) async {
      final repository = ref.watch(portfolioRepositoryProvider);
      final dateRange = ref.watch(performanceDateRangeProvider);

      // Watch all filters
      final markets = ref.watch(performanceSelectedMarketsProvider);
      final installedBy = ref.watch(performanceSelectedInstalledByProvider);
      final inverterManufacturers = ref.watch(
        performanceSelectedInverterManufacturersProvider,
      );

      return repository.getPerformanceRatio(
        from: dateRange.start,
        to: dateRange.end,
        granularity: getGranularity(dateRange),
        markets: markets,
        installedBy: installedBy,
        inverterManufacturers: inverterManufacturers,
      );
    });

final zeroProductionProvider =
    FutureProvider<List<ZeroProductionDataPointEntity>>((ref) async {
      final repository = ref.watch(portfolioRepositoryProvider);
      final dateRange = ref.watch(performanceDateRangeProvider);

      // Watch all filters
      final markets = ref.watch(performanceSelectedMarketsProvider);
      final installedBy = ref.watch(performanceSelectedInstalledByProvider);
      final inverterManufacturers = ref.watch(
        performanceSelectedInverterManufacturersProvider,
      );

      return repository.getZeroProductionSystems(
        from: dateRange.start,
        to: dateRange.end,
        granularity: getGranularity(dateRange),
        markets: markets,
        installedBy: installedBy,
        inverterManufacturers: inverterManufacturers,
      );
    });

// Non-Comms pagination & search state providers
final nonCommsPageProvider = StateProvider<int>((ref) => 1);
final nonCommsSearchQueryProvider = StateProvider<String>((ref) => '');
final nonCommsSortFieldProvider = StateProvider<String>((ref) => 'siteAddress');
final nonCommsSortDirectionProvider = StateProvider<String>((ref) => 'asc');

final nonCommsProvider = FutureProvider<NonCommsResponseEntity>((ref) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  final dateRange = ref.watch(performanceDateRangeProvider);

  // Watch all filters
  final markets = ref.watch(performanceSelectedMarketsProvider);
  final installedBy = ref.watch(performanceSelectedInstalledByProvider);
  final inverterManufacturers = ref.watch(
    performanceSelectedInverterManufacturersProvider,
  );

  // Watch pagination, search and sorting
  final page = ref.watch(nonCommsPageProvider);
  final searchQuery = ref.watch(nonCommsSearchQueryProvider);
  final sortBy = ref.watch(nonCommsSortFieldProvider);
  final sortOrder = ref.watch(nonCommsSortDirectionProvider);

  return repository.getNonCommsSystems(
    from: dateRange.start,
    to: dateRange.end,
    markets: markets,
    installedBy: installedBy,
    inverterManufacturers: inverterManufacturers,
    page: page,
    pageSize: 10,
    searchQuery: searchQuery.trim().isEmpty ? null : searchQuery,
    sortBy: sortBy,
    sortOrder: sortOrder,
  );
});
