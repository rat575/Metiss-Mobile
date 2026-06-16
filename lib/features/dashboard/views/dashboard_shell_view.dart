import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/api_keys/views/api_keys_view.dart';
import 'package:mobile/features/diagnostics/views/diagnostics_view.dart';
import 'package:mobile/features/documentation/views/documentation_view.dart';
import 'package:mobile/features/portfolio/views/portfolio_view.dart';
import 'package:mobile/features/registration/views/registration_view.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/dashboard_navigation_provider.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/dashboard_nav_item.dart';

class DashboardShellView extends ConsumerWidget {
  const DashboardShellView({super.key});

  static const List<Widget> _pages = [
    PortfolioView(),
    DiagnosticsView(),
    RegistrationView(),
    ApiKeysView(),
    DocumentsView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(dashboardNavigationProvider);

    return Scaffold(
      appBar: const DashboardAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: _pages[currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: .08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DashboardNavItem(
                  icon: Icons.pie_chart_rounded,
                  label: 'Portfolio',
                  isSelected: currentIndex == 0,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .setIndex(0),
                ),
                DashboardNavItem(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Diagnostics',
                  isSelected: currentIndex == 1,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .setIndex(1),
                ),
                DashboardNavItem(
                  icon: Icons.app_registration_rounded,
                  label: 'Registration',
                  isSelected: currentIndex == 2,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .setIndex(2),
                ),
                DashboardNavItem(
                  icon: Icons.vpn_key_rounded,
                  label: 'API Keys',
                  isSelected: currentIndex == 3,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .setIndex(3),
                ),
                DashboardNavItem(
                  icon: Icons.description_rounded,
                  label: 'Documents',
                  isSelected: currentIndex == 4,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .setIndex(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
