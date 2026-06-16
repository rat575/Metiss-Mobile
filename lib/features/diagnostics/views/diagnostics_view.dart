import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class DiagnosticsView extends ConsumerStatefulWidget {
  const DiagnosticsView({super.key});

  @override
  ConsumerState<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends ConsumerState<DiagnosticsView> {
  final _searchController = TextEditingController();
  bool _detailsExpanded = false;
  bool _portfolioExpanded = false;
  bool _performanceExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: const Color(0xFF889492)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Address',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor.withValues(alpha: .5),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF889492),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: const Color(0xFF889492)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: const Text(
                  'Select System',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCACECE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Customer / System Details section
          _buildAccordion(
            title: 'Customer / System Details',
            color: const Color(0xFF6ED0FC),
            isExpanded: _detailsExpanded,
            onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search for a customer to see details',
                    style: TextStyle(fontSize: 14, color: Color(0xFF889492)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Portfolio Metrics
          _buildAccordion(
            title: 'Portfolio Metrics',
            color: const Color(0xFF00C49C),
            isExpanded: _portfolioExpanded,
            onTap: () =>
                setState(() => _portfolioExpanded = !_portfolioExpanded),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System generated:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatColumn('0 kWh', 'Yesterday'),
                      _buildStatColumn('0 kWh', 'Last 30 Days'),
                      _buildStatColumn('0 kWh', 'All Time'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Chart placeholder
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDAE3E1)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.show_chart_rounded,
                            size: 40,
                            color: Color(0xFFDAE3E1),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Select a system to view chart',
                            style: TextStyle(
                              color: Color(0xFF889492),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Performance Metrics
          _buildAccordion(
            title: 'Performance Metrics',
            color: const Color(0xFFFFB000),
            isExpanded: _performanceExpanded,
            onTap: () =>
                setState(() => _performanceExpanded = !_performanceExpanded),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFFFFAE5)),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPerfTab('Zero Production', true),
                        const SizedBox(width: 8),
                        _buildPerfTab('Non-Comms', false),
                        const SizedBox(width: 8),
                        _buildPerfTab('Performance Ratio', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDAE3E1)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            size: 40,
                            color: Color(0xFFDAE3E1),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Select a system to view metrics',
                            style: TextStyle(
                              color: Color(0xFF889492),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAccordion({
    required String title,
    required Color color,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: color),
                right: BorderSide(color: color),
                bottom: BorderSide(color: color),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: child,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFB000) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? null : Border.all(color: const Color(0xFFE5E8E7)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFB000).withValues(alpha: .3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? AppTheme.primaryColor : const Color(0xFF889492),
        ),
      ),
    );
  }
}
