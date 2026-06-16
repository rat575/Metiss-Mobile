import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/registration_models.dart';
import '../../../../core/theme/app_theme.dart';

class AssetDetailsDialog extends StatelessWidget {
  final RegistrationListEntry entry;
  final SystemDetails system;

  const AssetDetailsDialog({
    super.key,
    required this.entry,
    required this.system,
  });

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

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'N/A';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'N/A';
    if (digits.length <= 3) return '($digits';
    if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, digits.length > 10 ? 10 : digits.length)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 8.0,
                top: 12.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${system.name} Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF889492),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E5E5), height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. User Details
                    _buildSectionHeader('User Details'),
                    _buildDetailRow('First Name:', entry.customer.firstName),
                    _buildDetailRow('Last Name:', entry.customer.lastName),
                    _buildDetailRow('Email:', entry.customer.email),
                    _buildDetailRow(
                      'Mobile Number:',
                      _formatPhone(entry.customer.phone),
                    ),

                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE5EAEA), height: 1),

                    // 2. Site Details
                    _buildSectionHeader('Site Details'),
                    _buildDetailRow(
                      'Site Street Address:',
                      entry.site.siteAddress,
                    ),
                    _buildDetailRow('City:', entry.site.city),
                    _buildDetailRow('State:', entry.site.state),
                    _buildDetailRow('Zip Code:', entry.site.zipCode),

                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE5EAEA), height: 1),

                    // 3. System Details
                    _buildSectionHeader('System Details'),
                    _buildDetailRow('Asset Owner:', system.assetOwner ?? 'N/A'),
                    _buildDetailRow(
                      'Installed By:',
                      system.installedBy.isEmpty ? 'N/A' : system.installedBy,
                    ),
                    _buildDetailRow(
                      'Solar System Size (DC):',
                      system.size ?? 'N/A',
                    ),
                    _buildDetailRow('Status:', system.status),
                    _buildDetailRow(
                      'Installation Date:',
                      _formatDate(system.installationDate),
                    ),
                    _buildDetailRow(
                      'Activation Date:',
                      _formatDate(system.activationDate),
                    ),
                    _buildDetailRow(
                      'Monitoring Start Date:',
                      _formatDate(system.monitoringStartDate),
                    ),

                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE5EAEA), height: 1),

                    // 4. Panel Details
                    _buildSectionHeader('Panel Details'),
                    _buildDetailRow(
                      'Number of Panels:',
                      system.panelCount?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Manufacturer:',
                      system.panelManufacturer ?? 'N/A',
                    ),
                    _buildDetailRow('Series:', system.panelSeries ?? 'N/A'),
                    _buildDetailRow(
                      'Wattage:',
                      system.panelWattage != null
                          ? '${system.panelWattage} W'
                          : 'N/A',
                    ),

                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE5EAEA), height: 1),

                    // 5. Inverter Details
                    _buildSectionHeader('Inverter Details'),
                    if (system.inverters.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'No inverter data',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF889492),
                          ),
                        ),
                      )
                    else
                      ...system.inverters.asMap().entries.map((item) {
                        final index = item.key;
                        final details = item.value['details'] as Map? ?? {};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inverter #${index + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              _buildDetailRow(
                                'Manufacturer:',
                                details['manufacturer'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Model:',
                                details['model'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Size:',
                                details['size'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Serial #:',
                                details['serial'] ?? 'N/A',
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE5EAEA), height: 1),

                    // 6. Storage Details
                    _buildSectionHeader('Storage Details'),
                    if (system.storages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'No storage data',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF889492),
                          ),
                        ),
                      )
                    else
                      ...system.storages.asMap().entries.map((item) {
                        final index = item.key;
                        final details = item.value['details'] as Map? ?? {};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battery #${index + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              _buildDetailRow(
                                'Manufacturer:',
                                details['manufacturer'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Model:',
                                details['model'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Size:',
                                details['size'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Serial #:',
                                details['serial'] ?? 'N/A',
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            const Divider(color: Color(0xFFE5E5E5), height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF889492),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF01372C),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF889492),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF01372C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
