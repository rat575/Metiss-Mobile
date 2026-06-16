import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardNavigationNotifier extends StateNotifier<int> {
  DashboardNavigationNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }
}

final dashboardNavigationProvider =
    StateNotifierProvider<DashboardNavigationNotifier, int>((ref) {
      return DashboardNavigationNotifier();
    });
