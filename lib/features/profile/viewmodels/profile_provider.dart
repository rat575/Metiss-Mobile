import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import '../repositories/profile_repository_provider.dart';

class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileNotifier(this._profileRepository) : super(ProfileState());

  Future<void> fetchProfile(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _profileRepository.fetchProfile(email);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> updateProfile(ProfileModel updatedProfile) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _profileRepository.updateProfile(updatedProfile.uuid, updatedProfile);
      state = state.copyWith(profile: updatedProfile, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(profileRepository);
});
