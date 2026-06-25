import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/user_entity.dart';
import '../repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final String _baseUrl =
      dotenv.env['API_BASE_URL'] ??
      'https://metiss-ai-gateway-6m7odqj.wl.gateway.dev';

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User not found after sign in');
      }

      return UserEntity(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('--- FIREBASE AUTH EXCEPTION ---');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('-------------------------------');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unknown error occurred during login');
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unknown error occurred during password reset');
    }
  }

  @override
  Future<String?> getIdToken() async {
    return await _firebaseAuth.currentUser?.getIdToken();
  }

  @override
  Future<UserEntity?> fetchUserInfo(String email) async {
    try {
      final token = await getIdToken();
      if (token == null) return null;

      final dio = Dio();
      final response = await dio.get(
        '$_baseUrl/v1/users/email',
        queryParameters: {'email': email},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data != null) {
        final user = _firebaseAuth.currentUser;
        return UserEntity.fromJson(response.data, user?.uid ?? '');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'invalid-email':
        return Exception('The email address is badly formatted.');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later.');
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}
