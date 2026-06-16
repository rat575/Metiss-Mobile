import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/portfolio_entities.dart';
import '../../viewmodels/portfolio_provider.dart';
import '../../../../core/theme/app_theme.dart';

class NonCommsList extends ConsumerStatefulWidget {
  const NonCommsList({super.key});

  @override
  ConsumerState<NonCommsList> createState() => _NonCommsListState();
}

class _NonCommsListState extends ConsumerState<NonCommsList> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Retrieve current query value to pre-populate text field
    final currentQuery = ref.read(nonCommsSearchQueryProvider);
    _searchController.text = currentQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(nonCommsPageProvider.notifier).state = 1; // Reset to page 1
      ref.read(nonCommsSearchQueryProvider.notifier).state = query;
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        return DateFormat('MMM dd, yyyy').format(parsed);
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final nonCommsState = ref.watch(nonCommsProvider);
    final currentPage = ref.watch(nonCommsPageProvider);
    final sortBy = ref.watch(nonCommsSortFieldProvider);
    final sortOrder = ref.watch(nonCommsSortDirectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search and Sorting Bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              // Search input field
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by system name or site address...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(
                      color: AppTheme.accentColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),

              // Sort Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFDAE3E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sortBy,
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              ref.read(nonCommsPageProvider.notifier).state = 1;
                              ref
                                      .read(nonCommsSortFieldProvider.notifier)
                                      .state =
                                  newValue;
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'siteAddress',
                              child: Text('Sort by Address'),
                            ),
                            DropdownMenuItem(
                              value: 'systemName',
                              child: Text('Sort by System Name'),
                            ),
                            DropdownMenuItem(
                              value: 'installedBy',
                              child: Text('Sort by Installer'),
                            ),
                            DropdownMenuItem(
                              value: 'manufacturer',
                              child: Text('Sort by Manufacturer'),
                            ),
                            DropdownMenuItem(
                              value: 'startDate',
                              child: Text('Sort by Start Date'),
                            ),
                            DropdownMenuItem(
                              value: 'endDate',
                              child: Text('Sort by End Date'),
                            ),
                            DropdownMenuItem(
                              value: 'alertDate',
                              child: Text('Sort by Alert Date'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFDAE3E1)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        sortOrder == 'asc'
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: AppTheme.primaryColor,
                        size: 20.0,
                      ),
                      onPressed: () {
                        ref.read(nonCommsPageProvider.notifier).state = 1;
                        ref.read(nonCommsSortDirectionProvider.notifier).state =
                            sortOrder == 'asc' ? 'desc' : 'asc';
                      },
                      tooltip: 'Toggle Sort Direction',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Data/Content Area
        nonCommsState.when(
          data: (nonCommsResponse) {
            final systems = nonCommsResponse.data;
            final totalCount = nonCommsResponse.total;
            final totalPages = (totalCount / 10).ceil();

            if (systems.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: Color(0xFF889492),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Offline Systems Found',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try relaxing your search query or filter parameters.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF889492),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // List of System Cards
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  //padding: const EdgeInsets.symmetric(),
                  itemCount: systems.length,
                  itemBuilder: (context, index) {
                    final system = systems[index];
                    return _buildSystemCard(system);
                  },
                ),
                const SizedBox(height: 16.0),

                // 3. Pagination bar
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 8.0,
                      bottom: 24.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFDAE3E1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: currentPage > 1
                                  ? () {
                                      ref
                                              .read(
                                                nonCommsPageProvider.notifier,
                                              )
                                              .state =
                                          currentPage - 1;
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: currentPage > 1
                                        ? const Color(0xFFDAE3E1)
                                        : const Color(0xFFECEFF1),
                                  ),
                                  color: currentPage > 1
                                      ? const Color(0xFFF5F7F6)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chevron_left_rounded,
                                      size: 18,
                                      color: currentPage > 1
                                          ? AppTheme.primaryColor
                                          : const Color(0xFFB0BEC5),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Prev',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: currentPage > 1
                                            ? AppTheme.primaryColor
                                            : const Color(0xFFB0BEC5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Page Info text
                          Text(
                            '$currentPage / $totalPages',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),

                          // Next Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: currentPage < totalPages
                                  ? () {
                                      ref
                                              .read(
                                                nonCommsPageProvider.notifier,
                                              )
                                              .state =
                                          currentPage + 1;
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: currentPage < totalPages
                                        ? const Color(0xFFDAE3E1)
                                        : const Color(0xFFECEFF1),
                                  ),
                                  color: currentPage < totalPages
                                      ? const Color(0xFFF5F7F6)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Next',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: currentPage < totalPages
                                            ? AppTheme.primaryColor
                                            : const Color(0xFFB0BEC5),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: currentPage < totalPages
                                          ? AppTheme.primaryColor
                                          : const Color(0xFFB0BEC5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: 16.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8615A).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFE8615A),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load non-comms metrics',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE8615A),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF889492),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(nonCommsProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8615A),
                      minimumSize: const Size(120, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemCard(NonCommsSystemEntity system) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFDAE3E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: System Name and address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        system.systemName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFF889492),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              system.siteAddress,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF889492),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Divider(color: Color(0xFFE5E8E7), height: 1),
            const SizedBox(height: 12.0),

            // System Details Grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Manufacturer',
                    system.manufacturer.isEmpty ? 'N/A' : system.manufacturer,
                    Icons.solar_power_rounded,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Installer',
                    system.installedBy.isEmpty ? 'N/A' : system.installedBy,
                    Icons.build_circle_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Start',
                    _formatDate(system.startDate),
                    Icons.calendar_today_rounded,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'End',
                    _formatDate(system.endDate),
                    Icons.event_available_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Alert Date',
                    system.alertDate == null || system.alertDate!.isEmpty
                        ? 'N/A'
                        : _formatDate(system.alertDate),
                    Icons.notification_important_rounded,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF889492)),
        const SizedBox(width: 6.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF889492),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
