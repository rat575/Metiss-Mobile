import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/repositories/auth_repository_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final authRepository = ref.watch(authRepositoryProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await authRepository.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // Handle token fetch error if needed
          debugPrint('Error getting ID token: $e');
        }
        return handler.next(options);
      },
    ),
  );

  return dio;
});
