import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> fetchProfile(String email);
  Future<void> updateProfile(String uuid, ProfileModel profile);
}
