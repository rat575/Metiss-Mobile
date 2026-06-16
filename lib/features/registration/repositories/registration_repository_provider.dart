import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'registration_repository_impl.dart';
import '../services/registration_remote_source.dart';
import '../../../core/network/dio_provider.dart';

final registrationRemoteSourceProvider = Provider<RegistrationRemoteDataSource>(
  (ref) {
    final dio = ref.watch(dioProvider);
    return RegistrationRemoteDataSource(dio);
  },
);

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  final remoteSource = ref.watch(registrationRemoteSourceProvider);
  return RegistrationRepositoryImpl(remoteSource);
});
