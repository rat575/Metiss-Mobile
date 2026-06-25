import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/registration_repository_impl.dart';
import '../repositories/registration_repository_provider.dart';

class ManualRegistrationState {
  final bool isSaving;
  final bool success;
  final String? error;
  final List<dynamic> predictions;
  final bool isFetchingPredictions;
  final bool isFetchingDetails;

  ManualRegistrationState({
    this.isSaving = false,
    this.success = false,
    this.error,
    this.predictions = const [],
    this.isFetchingPredictions = false,
    this.isFetchingDetails = false,
  });

  ManualRegistrationState copyWith({
    bool? isSaving,
    bool? success,
    String? error,
    List<dynamic>? predictions,
    bool? isFetchingPredictions,
    bool? isFetchingDetails,
  }) {
    return ManualRegistrationState(
      isSaving: isSaving ?? this.isSaving,
      success: success ?? this.success,
      error: error,
      predictions: predictions ?? this.predictions,
      isFetchingPredictions:
          isFetchingPredictions ?? this.isFetchingPredictions,
      isFetchingDetails: isFetchingDetails ?? this.isFetchingDetails,
    );
  }
}

class ManualRegistrationNotifier
    extends StateNotifier<ManualRegistrationState> {
  final RegistrationRepository _repository;

  ManualRegistrationNotifier(this._repository)
    : super(ManualRegistrationState());

  Future<bool> registerAsset(Map<String, dynamic> payload) async {
    state = state.copyWith(isSaving: true, success: false, error: null);
    try {
      await _repository.registerAsset(payload);
      state = state.copyWith(isSaving: false, success: true);
      return true;
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'] ?? data['error'] ?? data['msg'];
          if (msg != null) {
            errorMessage = msg.toString();
          }
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }
      }

      final lowerMessage = errorMessage.toLowerCase();
      if (lowerMessage.contains('email already exists') ||
          lowerMessage.contains('gmail already exists') ||
          lowerMessage.contains('email_already_exists') ||
          (e is DioException && e.response?.statusCode == 409)) {
        errorMessage = 'Email already exists';
      }

      state = state.copyWith(
        isSaving: false,
        success: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> fetchAddressPredictions(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(predictions: [], isFetchingPredictions: false);
      return;
    }
    state = state.copyWith(isFetchingPredictions: true);
    try {
      final predictions = await _repository.getAddressPredictions(query);
      state = state.copyWith(
        predictions: predictions,
        isFetchingPredictions: false,
      );
    } catch (e) {
      state = state.copyWith(predictions: [], isFetchingPredictions: false);
    }
  }

  Future<Map<String, dynamic>?> fetchPlaceDetails(
    String placeId,
    String address,
  ) async {
    state = state.copyWith(isFetchingDetails: true);
    try {
      final details = await _repository.getPlaceDetails(placeId, address);
      state = state.copyWith(isFetchingDetails: false);
      return details;
    } catch (e) {
      state = state.copyWith(isFetchingDetails: false);
      return null;
    }
  }

  void clearPredictions() {
    state = state.copyWith(predictions: []);
  }

  void reset() {
    state = ManualRegistrationState();
  }
}

final manualRegistrationProvider =
    StateNotifierProvider<ManualRegistrationNotifier, ManualRegistrationState>((
      ref,
    ) {
      final repository = ref.watch(registrationRepositoryProvider);
      return ManualRegistrationNotifier(repository);
    });
