import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/profile_model.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio _dio;
  final String _baseUrl;

  ProfileRepositoryImpl(this._dio)
      : _baseUrl = dotenv.env['API_BASE_URL'] ??
            'https://metiss-ai-gateway-6m7odqj.wl.gateway.dev';

  @override
  Future<ProfileModel> fetchProfile(String email) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/v1/users/email',
        queryParameters: {'email': email},
      );

      if (response.data != null) {
        return ProfileModel.fromJson(response.data);
      }
      throw Exception('Failed to load user profile data');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(String uuid, ProfileModel profile) async {
    try {
      final payload = {
        'params': profile.toJson(),
      };

      await _dio.put(
        '$_baseUrl/v1/users/$uuid',
        data: payload,
      );
    } catch (e) {
      rethrow;
    }
  }
}
