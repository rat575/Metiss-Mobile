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

  Future<void> registerAsset(Map<String, dynamic> payload);
  Future<List<dynamic>> getAddressPredictions(String query);
  Future<Map<String, dynamic>> getPlaceDetails(String placeId, String address);
  Future<Map<String, dynamic>> getManufacturerDetails();
  Future<RegistrationListEntry> getRegistrationBySystemUuid(String systemUuid);
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

  @override
  Future<void> registerAsset(Map<String, dynamic> payload) {
    return _remoteDataSource.registerAsset(payload);
  }

  @override
  Future<List<dynamic>> getAddressPredictions(String query) {
    return _remoteDataSource.getAddressPredictions(query);
  }

  @override
  Future<Map<String, dynamic>> getPlaceDetails(String placeId, String address) {
    return _remoteDataSource.getPlaceDetails(placeId, address);
  }

  @override
  Future<Map<String, dynamic>> getManufacturerDetails() {
    return _remoteDataSource.getManufacturerDetails();
  }

  @override
  Future<RegistrationListEntry> getRegistrationBySystemUuid(String systemUuid) {
    return _remoteDataSource.getRegistrationBySystemUuid(systemUuid);
  }
}
