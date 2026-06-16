import '../models/registration_models.dart';
import '../services/registration_remote_source.dart';

abstract class RegistrationRepository {
  Future<RegistrationListResponse> getRegistrationSystems({
    required int page,
    required int pageSize,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
    String? status,
  });
}

class RegistrationRepositoryImpl implements RegistrationRepository {
  final RegistrationRemoteDataSource _remoteDataSource;

  RegistrationRepositoryImpl(this._remoteDataSource);

  @override
  Future<RegistrationListResponse> getRegistrationSystems({
    required int page,
    required int pageSize,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
    String? status,
  }) {
    return _remoteDataSource.getRegistrationSystems(
      page: page,
      pageSize: pageSize,
      searchQuery: searchQuery,
      sortBy: sortBy,
      sortOrder: sortOrder,
      status: status,
    );
  }
}
