import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import 'documentation_repository.dart';

final documentationRepositoryProvider = Provider<DocumentationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DocumentationRepositoryImpl(dio);
});
