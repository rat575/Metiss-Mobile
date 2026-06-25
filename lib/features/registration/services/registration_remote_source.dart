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

  Future<RegistrationListEntry> getRegistrationBySystemUuid(String systemUuid) async {
    try {
      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring/systems/$systemUuid',
      );
      if (response.data != null) {
        return RegistrationListEntry.fromJson(response.data);
      }
      throw Exception('Invalid system registration response');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerAsset(Map<String, dynamic> payload) async {
    try {
      await _dio.put(
        '$baseUrl/v1/asset-monitoring/registration',
        data: payload,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAddressPredictions(String query) async {
    try {
      final response = await _dio.get(
        '$baseUrl/v1/maps/autocomplete',
        queryParameters: {'input': query},
      );
      if (response.data != null) {
        return response.data['predictions'] as List? ?? [];
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(
    String placeId,
    String address,
  ) async {
    try {
      final response = await _dio.get(
        '$baseUrl/v1/maps/place-details',
        queryParameters: {
          'place_id': placeId,
          'address': address,
        },
      );
      if (response.data != null) {
        return response.data['result'] as Map<String, dynamic>? ?? {};
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getManufacturerDetails() async {
    try {
      final response = await _dio.get(
        '$baseUrl/v1/asset-monitoring/registration/manufacturer-details',
      );
      if (response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }
}
