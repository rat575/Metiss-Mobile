import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/models/profile_model.dart';
import 'package:mobile/features/profile/viewmodels/profile_provider.dart';
import 'package:mobile/features/profile/views/profile_view.dart';
import 'package:mobile/features/profile/repositories/profile_repository.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:mobile/features/auth/repositories/auth_repository.dart';
import 'package:mobile/features/auth/models/user_entity.dart';
import 'package:mobile/features/auth/viewmodels/auth_provider.dart';

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<ProfileModel> fetchProfile(String email) async => throw UnimplementedError();
  @override
  Future<void> updateProfile(String uuid, ProfileModel profile) async {}
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> login(String email, String password) async => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<String?> getIdToken() async => 'mock-token';
  @override
  Future<UserEntity?> fetchUserInfo(String email) async => null;
}

class MockProfileNotifier extends ProfileNotifier {
  MockProfileNotifier(ProfileState state) : super(FakeProfileRepository()) {
    this.state = state;
  }

  @override
  Future<void> fetchProfile(String email) async {}

  @override
  Future<bool> updateProfile(ProfileModel updatedProfile) async {
    return true;
  }
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(AuthState state) : super(FakeAuthRepository()) {
    this.state = state;
  }
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  testWidgets('ProfileView lays out correctly', (WidgetTester tester) async {
    final mockState = ProfileState(
      profile: ProfileModel(
        uuid: '123-uuid',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        jobTitle: 'Software Engineer',
        phone: '1234567890',
        communicationPreference: 'EMAIL',
        permissions: ['DEFAULT', 'DEVELOPMENT_CENTER'],
        status: 'ACTIVE',
      ),
      isLoading: false,
    );

    final mockAuthState = AuthState(
      user: UserEntity(
        id: '123-uuid',
        email: 'john.doe@example.com',
        name: 'John Doe',
        firstName: 'John',
        lastName: 'Doe',
      ),
      isLoading: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => MockProfileNotifier(mockState)),
          authProvider.overrideWith((ref) => MockAuthNotifier(mockAuthState)),
        ],
        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Doe'), findsOneWidget);
  });

  testWidgets('ProfileView renders correctly with initial null profile state', (WidgetTester tester) async {
    final mockState = ProfileState(
      profile: null,
      isLoading: false,
      error: null,
    );

    final mockAuthState = AuthState(
      user: UserEntity(
        id: '123-uuid',
        email: 'john.doe@example.com',
        name: 'John Doe',
        firstName: 'John',
        lastName: 'Doe',
      ),
      isLoading: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => MockProfileNotifier(mockState)),
          authProvider.overrideWith((ref) => MockAuthNotifier(mockAuthState)),
        ],
        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pump(); // Pump first frame

    expect(find.text('Personal Information'), findsOneWidget);
  });
}
