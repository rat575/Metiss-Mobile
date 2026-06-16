import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/registration_models.dart';

class RegistrationRemoteDataSource {
  final Dio _dio;
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  RegistrationRemoteDataSource(this._dio);

  Future<RegistrationListResponse> getRegistrationSystems({
    required int page,
    required int pageSize,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring/systems',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'search': searchQuery,
          if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
          if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
          if (status != null && status != 'all') 'status': status.toUpperCase(),
        },
      );

      if (response.data != null) {
        return RegistrationListResponse.fromJson(response.data);
      }
      throw Exception('Invalid systems registration response');
    } catch (e) {
      rethrow;
    }
  }
}
