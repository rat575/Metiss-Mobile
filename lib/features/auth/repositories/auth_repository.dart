import '../models/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<String?> getIdToken();
  Future<UserEntity?> fetchUserInfo(String email);
}
