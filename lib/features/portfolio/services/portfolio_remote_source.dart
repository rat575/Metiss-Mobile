import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/portfolio_models.dart';

class PortfolioRemoteDataSource {
  final Dio _dio;

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  PortfolioRemoteDataSource(this._dio);

  Future<PortfolioMetricsModel> getPortfolioMetrics() async {
    try {
      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring-service/portfolio/metrics',
        queryParameters: {
          'timezoneOffset': (-DateTime.now().timeZoneOffset.inMinutes)
              .toString(),
        },
      );
      if (response.data != null && response.data['metrics'] != null) {
        return PortfolioMetricsModel.fromJson(response.data['metrics']);
      }
      throw Exception('Invalid metrics response');
    } catch (e) {
      rethrow;
    }
  }

  Future<PortfolioFilterOptionsModel> getPortfolioFilters() async {
    try {
      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring-service/portfolio/filters',
        queryParameters: {
          'timezoneOffset': (-DateTime.now().timeZoneOffset.inMinutes)
              .toString(),
        },
      );

      if (response.data != null) {
        return PortfolioFilterOptionsModel.fromJson(response.data);
      }
      throw Exception('Invalid filters response');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EnergyDataPointModel>> getPortfolioGraphData({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) async {
    try {
      // Apply special formatting for installedBy as required by backend (seen in web code)
      final formattedInstalledBy = installedBy?.map((e) => '{$e}').toList();

      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring-service/portfolio/graph',
        queryParameters: {
          'from': DateTime.utc(
            from.year,
            from.month,
            from.day,
            0,
            0,
            0,
          ).toIso8601String(),
          'to': DateTime.utc(
            to.year,
            to.month,
            to.day,
            23,
            59,
            59,
            999,
          ).toIso8601String(),
          'granularity': granularity,
          'timezoneOffset': (-DateTime.now().timeZoneOffset.inMinutes)
              .toString(),
          if (markets != null && markets.isNotEmpty)
            'markets': markets.join(','),
          if (formattedInstalledBy != null && formattedInstalledBy.isNotEmpty)
            'installedBy': formattedInstalledBy.join(','),
          if (inverterManufacturers != null && inverterManufacturers.isNotEmpty)
            'inverterManufacturers': inverterManufacturers.join(','),
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => EnergyDataPointModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SystemsDataPointModel>> getSystemsSummary({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) async {
    try {
      final formattedInstalledBy = installedBy?.map((e) => '{$e}').toList();

      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring-service/portfolio/system-summary',
        queryParameters: {
          'from': DateTime.utc(
            from.year,
            from.month,
            from.day,
            0,
            0,
            0,
          ).toIso8601String(),
          'to': DateTime.utc(
            to.year,
            to.month,
            to.day,
            23,
            59,
            59,
            999,
          ).toIso8601String(),
          'granularity': granularity == 'quarterly' ? 'yearly' : granularity,
          'timezoneOffset': (-DateTime.now().timeZoneOffset.inMinutes)
              .toString(),
          if (markets != null && markets.isNotEmpty)
            'markets': markets.join(','),
          if (formattedInstalledBy != null && formattedInstalledBy.isNotEmpty)
            'installedBy': formattedInstalledBy.join(','),
          if (inverterManufacturers != null && inverterManufacturers.isNotEmpty)
            'inverterManufacturers': inverterManufacturers.join(','),
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data
            .map((json) => SystemsDataPointModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PerformanceRatioDataPointModel>> getPerformanceRatio({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) async {
    try {
      final formattedInstalledBy = installedBy?.map((e) => '{$e}').toList();

      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring-service/portfolio/performance-ratio',
        queryParameters: {
          'from': DateTime.utc(
            from.year,
            from.month,
            from.day,
            0,
            0,
            0,
          ).toIso8601String(),
          'to': DateTime.utc(
            to.year,
            to.month,
            to.day,
            23,
            59,
            59,
            999,
          ).toIso8601String(),
          'granularity': granularity == 'quarterly' ? 'yearly' : granularity,
          'timezoneOffset': (-DateTime.now().timeZoneOffset.inMinutes)
              .toString(),
          if (markets != null && markets.isNotEmpty)
            'markets': markets.join(','),
          if (formattedInstalledBy != null && formattedInstalledBy.isNotEmpty)
            'installedBy': formattedInstalledBy.join(','),
          if (inverterManufacturers != null && inverterManufacturers.isNotEmpty)
            'inverterManufacturers': inverterManufacturers.join(','),
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data
            .map((json) => PerformanceRatioDataPointModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ZeroProductionDataPointModel>> getZeroProductionSystems({
    required DateTime from,
    required DateTime to,
    String granularity = 'monthly',
    List<String>? markets,
    List<String>? installedBy,
    List<String>? inverterManufacturers,
  }) async {
    try {
      final formattedInstalledBy = installedBy?.map((e) => '{$e}').toList();

      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring-service/portfolio/zero-production-systems',
        queryParameters: {
          'from': DateTime.utc(
            from.year,
            from.month,
            from.day,
            0,
            0,
            0,
          ).toIso8601String(),
          'to': DateTime.utc(
            to.year,
            to.month,
            to.day,
            23,
            59,
            59,
            999,
          ).toIso8601String(),
          'granularity': granularity == 'quarterly' ? 'yearly' : granularity,
          'timezoneOffset': (-DateTime.now().timeZoneOffset.inMinutes)
              .toString(),
          if (markets != null && markets.isNotEmpty)
            'markets': markets.join(','),
          if (formattedInstalledBy != null && formattedInstalledBy.isNotEmpty)
            'installedBy': formattedInstalledBy.join(','),
          if (inverterManufacturers != null && inverterManufacturers.isNotEmpty)
            'inverterManufacturers': inverterManufacturers.join(','),
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data
            .map((json) => ZeroProductionDataPointModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<NonCommsResponseModel> getNonCommsSystems({
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
  }) async {
    try {
      final formattedInstalledBy = installedBy?.map((e) => '{$e}').toList();

      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring-service/system-metrics',
        queryParameters: {
          'from': DateTime.utc(
            from.year,
            from.month,
            from.day,
            0,
            0,
            0,
          ).toIso8601String(),
          'to': DateTime.utc(
            to.year,
            to.month,
            to.day,
            23,
            59,
            59,
            999,
          ).toIso8601String(),
          'metricConfigType': 'PORTFOLIO',
          'metricType': 'NON_COMM',
          'timezoneOffset': (-DateTime.now().timeZoneOffset.inMinutes)
              .toString(),
          'page': page,
          'pageSize': pageSize,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'searchQuery': searchQuery,
          if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
          if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
          if (markets != null && markets.isNotEmpty)
            'markets': markets.join(','),
          if (formattedInstalledBy != null && formattedInstalledBy.isNotEmpty)
            'installedBy': formattedInstalledBy.join(','),
          if (inverterManufacturers != null && inverterManufacturers.isNotEmpty)
            'inverterManufacturers': inverterManufacturers.join(','),
        },
      );

      if (response.data != null) {
        return NonCommsResponseModel.fromJson(response.data);
      }
      throw Exception('Invalid non-comms response');
    } catch (e) {
      rethrow;
    }
  }
}
