import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/registration_models.dart';
import '../repositories/registration_repository_provider.dart';

final registrationPageProvider = StateProvider<int>((ref) => 1);
final registrationSearchQueryProvider = StateProvider<String>((ref) => '');
final registrationSortFieldProvider = StateProvider<String>(
  (ref) => 'customerName',
);
final registrationSortDirectionProvider = StateProvider<String>((ref) => 'asc');
final registrationStatusFilterProvider = StateProvider<String>((ref) => 'all');

final registrationListProvider = FutureProvider<RegistrationListResponse>((
  ref,
) async {
  final repository = ref.watch(registrationRepositoryProvider);
  final page = ref.watch(registrationPageProvider);
  final searchQuery = ref.watch(registrationSearchQueryProvider);
  final sortBy = ref.watch(registrationSortFieldProvider);
  final sortOrder = ref.watch(registrationSortDirectionProvider);
  final status = ref.watch(registrationStatusFilterProvider);

  return repository.getRegistrationSystems(
    page: page,
    pageSize: 10,
    searchQuery: searchQuery,
    sortBy: sortBy,
    sortOrder: sortOrder,
    status: status,
  );
});
