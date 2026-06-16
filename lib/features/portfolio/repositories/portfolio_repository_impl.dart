import 'package:mobile/features/portfolio/services/portfolio_remote_source.dart';

import '../models/portfolio_entities.dart';

abstract class PortfolioRepository {
  Future<PortfolioMetricsEntity> getPortfolioMetrics();
  Future<PortfolioFilterOptionsEntity> getPortfolioFilters();
  Future<List<EnergyDataPointEntity>> getPortfolioGraphData({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  });

  Future<List<SystemsDataPointEntity>> getSystemsSummary({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  });

  Future<List<PerformanceRatioDataPointEntity>> getPerformanceRatio({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  });

  Future<List<ZeroProductionDataPointEntity>> getZeroProductionSystems({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  });

  Future<NonCommsResponseEntity> getNonCommsSystems({
    required DateTime from,
    required DateTime to,
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
    required int page,
    required int pageSize,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
  });
}

class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioRemoteDataSource _remoteDataSource;

  PortfolioRepositoryImpl(this._remoteDataSource);

  @override
  Future<PortfolioMetricsEntity> getPortfolioMetrics() {
    return _remoteDataSource.getPortfolioMetrics();
  }

  @override
  Future<PortfolioFilterOptionsEntity> getPortfolioFilters() {
    return _remoteDataSource.getPortfolioFilters();
  }

  @override
  Future<List<EnergyDataPointEntity>> getPortfolioGraphData({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) {
    return _remoteDataSource.getPortfolioGraphData(
      from: from,
      to: to,
      granularity: granularity,
      markets: markets,
      installedBy: installedBy,
      inverterManufacturers: inverterManufacturers,
    );
  }

  @override
  Future<List<SystemsDataPointEntity>> getSystemsSummary({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) {
    return _remoteDataSource.getSystemsSummary(
      from: from,
      to: to,
      granularity: granularity,
      markets: markets,
      installedBy: installedBy,
      inverterManufacturers: inverterManufacturers,
    );
  }

  @override
  Future<List<PerformanceRatioDataPointEntity>> getPerformanceRatio({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) {
    return _remoteDataSource.getPerformanceRatio(
      from: from,
      to: to,
      granularity: granularity,
      markets: markets,
      installedBy: installedBy,
      inverterManufacturers: inverterManufacturers,
    );
  }

  @override
  Future<List<ZeroProductionDataPointEntity>> getZeroProductionSystems({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) {
    return _remoteDataSource.getZeroProductionSystems(
      from: from,
      to: to,
      granularity: granularity,
      markets: markets,
      installedBy: installedBy,
      inverterManufacturers: inverterManufacturers,
    );
  }

  @override
  Future<NonCommsResponseEntity> getNonCommsSystems({
    required DateTime from,
    required DateTime to,
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
    required int page,
    required int pageSize,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
  }) {
    return _remoteDataSource.getNonCommsSystems(
      from: from,
      to: to,
      markets: markets,
      installedBy: installedBy,
      inverterManufacturers: inverterManufacturers,
      page: page,
      pageSize: pageSize,
      searchQuery: searchQuery,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}
