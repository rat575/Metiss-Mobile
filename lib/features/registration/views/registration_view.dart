import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/registration_models.dart';
import '../viewmodels/registration_provider.dart';
import '../widgets/asset_details_dialog.dart';

class RegistrationView extends ConsumerStatefulWidget {
  const RegistrationView({super.key});

  @override
  ConsumerState<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends ConsumerState<RegistrationView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Retrieve current query value to pre-populate text field
    final currentQuery = ref.read(registrationSearchQueryProvider);
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
      ref.read(registrationPageProvider.notifier).state = 1; // Reset to page 1
      ref.read(registrationSearchQueryProvider.notifier).state = query;
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
    final registrationState = ref.watch(registrationListProvider);
    final currentPage = ref.watch(registrationPageProvider);
    final sortBy = ref.watch(registrationSortFieldProvider);
    final sortOrder = ref.watch(registrationSortDirectionProvider);
    final statusFilter = ref.watch(registrationStatusFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Asset Registration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: LucideIcons.edit,
            label: 'Manual Registration',
            color: const Color(0xFF00C49C),
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: LucideIcons.upload,
            label: 'Bulk Upload Registration',
            color: const Color(0xFF00C49C),
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Systems Title
          Text(
            'Systems',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // Search and Sorting Area (inspired by non_comms_list.dart)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by customer, address, or system...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.primaryColor.withValues(alpha: .4),
                    ),
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

                // Sort and Direction Row
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
                                ref
                                        .read(registrationPageProvider.notifier)
                                        .state =
                                    1;
                                ref
                                        .read(
                                          registrationSortFieldProvider
                                              .notifier,
                                        )
                                        .state =
                                    newValue;
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'customerName',
                                child: Text('Sort by Customer Name'),
                              ),
                              DropdownMenuItem(
                                value: 'address',
                                child: Text('Sort by Address'),
                              ),
                              DropdownMenuItem(
                                value: 'system',
                                child: Text('Sort by System Name'),
                              ),
                              DropdownMenuItem(
                                value: 'installedBy',
                                child: Text('Sort by Installer'),
                              ),
                              DropdownMenuItem(
                                value: 'installation',
                                child: Text('Sort by Installation Date'),
                              ),
                              DropdownMenuItem(
                                value: 'monitoring',
                                child: Text('Sort by Monitoring Date'),
                              ),
                              DropdownMenuItem(
                                value: 'status',
                                child: Text('Sort by Status'),
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
                          ref.read(registrationPageProvider.notifier).state = 1;
                          ref
                              .read(registrationSortDirectionProvider.notifier)
                              .state = sortOrder == 'asc'
                              ? 'desc'
                              : 'asc';
                        },
                        tooltip: 'Toggle Sort Direction',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Status Badges Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterBadge('All', 'all', statusFilter),
                const SizedBox(width: 8),
                _buildFilterBadge('Active', 'active', statusFilter),
                const SizedBox(width: 8),
                _buildFilterBadge('Inactive', 'inactive', statusFilter),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Content Area
          registrationState.when(
            data: (response) {
              final entries = response.result;
              final totalCount = response.total;
              final totalPages = (totalCount / 10).ceil();

              // Flatten entries so that each system is represented as a separate card
              final flattenedSystems = <Map<String, dynamic>>[];
              for (final entry in entries) {
                for (final sys in entry.system) {
                  flattenedSystems.add({'entry': entry, 'system': sys});
                }
              }

              if (flattenedSystems.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Color(0xFF889492),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Systems Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: flattenedSystems.length,
                    itemBuilder: (context, index) {
                      final item = flattenedSystems[index];
                      final entry = item['entry'] as RegistrationListEntry;
                      final system = item['system'] as SystemDetails;
                      return _buildRegistrationCard(entry, system);
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Pagination controls
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
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
                                                  registrationPageProvider
                                                      .notifier,
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

                            // Page Info Text
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
                                                  registrationPageProvider
                                                      .notifier,
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accentColor,
                  ),
                ),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
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
                      'Failed to load registered systems',
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
                      onPressed: () => ref.invalidate(registrationListProvider),
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
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBadge(String label, String value, String selectedValue) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () {
        ref.read(registrationPageProvider.notifier).state = 1;
        ref.read(registrationStatusFilterProvider.notifier).state = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C49C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFDAE3E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF5A6664),
          ),
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

  Widget _buildRegistrationCard(
    RegistrationListEntry entry,
    SystemDetails system,
  ) {
    final statusColor = system.status.toUpperCase() == 'ACTIVE'
        ? const Color(0xFF00C49C)
        : const Color(0xFF889492);
    final statusBgColor = system.status.toUpperCase() == 'ACTIVE'
        ? const Color(0xFFE6F9F5)
        : const Color(0xFFF5F7F6);

    return Material(
      color: Colors.transparent,
      child: Container(
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
              // Header: System Name and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.customer.firstName} ${entry.customer.lastName}',
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
                                entry.site.formattedAddress,
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      system.status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
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
                      'System Name',
                      system.name.isEmpty ? 'N/A' : system.name,
                      Icons.info_outline_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Installed By',
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
                      'Installation Date',
                      _formatDate(system.installationDate),
                      Icons.calendar_today_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Monitoring Start',
                      _formatDate(system.monitoringStartDate),
                      Icons.play_circle_fill_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),
              const Divider(color: Color(0xFFE5E8E7), height: 1),
              const SizedBox(height: 8.0),

              // Card Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF889492),
                      size: 20,
                    ),
                    onPressed: () {
                      // Action placeholder for edit
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit system ${system.name}')),
                      );
                    },
                    tooltip: 'Edit Asset',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.visibility_rounded,
                      color: Color(0xFF889492),
                      size: 20,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            AssetDetailsDialog(entry: entry, system: system),
                      );
                    },
                    tooltip: 'View Details',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
