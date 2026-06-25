import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/document_model.dart';

abstract class DocumentationRepository {
  Future<DocumentListResponse> getDocuments({
    required int page,
    required int perPage,
    String? sortBy,
    String? sortOrder,
    String? search,
  });

  Future<void> createDocument({
    required DateTime executedDate,
    required DateTime effectiveDate,
    required String documentType,
    required String serviceName,
    required String status,
    required String term,
    required File file,
  });
}

class DocumentationRepositoryImpl implements DocumentationRepository {
  final Dio _dio;
  final String _baseUrl;

  DocumentationRepositoryImpl(this._dio)
      : _baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://metiss-ai-gateway-6m7odqj.wl.gateway.dev';

  @override
  Future<DocumentListResponse> getDocuments({
    required int page,
    required int perPage,
    String? sortBy,
    String? sortOrder,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'perPage': perPage,
      };
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null) {
        queryParams['sortOrder'] = sortOrder;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _dio.get(
        '$_baseUrl/v1/asset-monitoring-service/documents',
        queryParameters: queryParams,
      );

      if (response.data != null) {
        return DocumentListResponse.fromJson(response.data);
      }
      throw Exception('Invalid response received from documents API');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> createDocument({
    required DateTime executedDate,
    required DateTime effectiveDate,
    required String documentType,
    required String serviceName,
    required String status,
    required String term,
    required File file,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'executedDate': executedDate.toIso8601String(),
        'effectiveDate': effectiveDate.toIso8601String(),
        'documentType': documentType,
        'serviceName': serviceName,
        'status': status,
        'term': term,
        'files': multipartFile,
      });

      await _dio.post(
        '$_baseUrl/v1/asset-monitoring-service/documents',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
