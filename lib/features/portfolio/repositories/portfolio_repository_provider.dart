import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'portfolio_repository_impl.dart';
import '../services/portfolio_remote_source.dart';
import '../../../core/network/dio_provider.dart';

final portfolioRemoteSourceProvider = Provider<PortfolioRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return PortfolioRemoteDataSource(dio);
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final remoteSource = ref.watch(portfolioRemoteSourceProvider);
  return PortfolioRepositoryImpl(remoteSource);
});
