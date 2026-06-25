import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../auth/viewmodels/auth_provider.dart';
import '../viewmodels/documentation_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

class AddDocumentView extends ConsumerStatefulWidget {
  const AddDocumentView({super.key});

  @override
  ConsumerState<AddDocumentView> createState() => _AddDocumentViewState();
}

class _AddDocumentViewState extends ConsumerState<AddDocumentView> {
  final _formKey = GlobalKey<FormState>();
  
  String? _documentType;
  String _serviceName = 'Asset Monitoring Service';
  String _status = 'Active';
  final _termController = TextEditingController();
  
  DateTime? _executedDate;
  DateTime? _effectiveDate;
  
  File? _selectedFile;
  String? _selectedFileName;
  double? _selectedFileSizeMb;
  
  bool _allowPop = false;
  String? _fileError;

  final List<String> _docTypes = [
    'Master Service Agreement',
    'Statement of Work',
    'Subscription',
  ];

  final List<String> _services = [
    'Asset Monitoring Service',
  ];

  final List<String> _statuses = [
    'Active',
    'Suspended',
  ];

  @override
  void dispose() {
    _termController.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges() {
    return _documentType != null ||
        _executedDate != null ||
        _effectiveDate != null ||
        _termController.text.trim().isNotEmpty ||
        _selectedFile != null;
  }

  Future<bool?> _showDiscardConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final sizeBytes = await file.length();
        final sizeMb = sizeBytes / (1024 * 1024);

        if (sizeMb > 4.0) {
          setState(() {
            _fileError = 'File size exceeds 4MB.';
            _selectedFile = null;
            _selectedFileName = null;
            _selectedFileSizeMb = null;
          });
          return;
        }

        setState(() {
          _fileError = null;
          _selectedFile = file;
          _selectedFileName = result.files.single.name;
          _selectedFileSizeMb = sizeMb;
        });
      }
    } catch (e) {
      setState(() {
        _fileError = 'Failed to pick file.';
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSizeMb = null;
      _fileError = null;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isExecutedDate) async {
    final DateTime initialDate = (isExecutedDate ? _executedDate : _effectiveDate) ?? DateTime.now();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExecutedDate) {
          _executedDate = picked;
        } else {
          _effectiveDate = picked;
        }
      });
    }
  }

  bool _isFormValid() {
    return _documentType != null &&
        _executedDate != null &&
        _effectiveDate != null &&
        _termController.text.trim().isNotEmpty &&
        _selectedFile != null;
  }

  Future<void> _handleSave() async {
    if (!_isFormValid()) return;

    final notifier = ref.read(documentationProvider.notifier);
    
    final success = await notifier.createDocument(
      executedDate: _executedDate!,
      effectiveDate: _effectiveDate!,
      documentType: _documentType!,
      serviceName: _serviceName,
      status: _status,
      term: _termController.text.trim(),
      file: _selectedFile!,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Document uploaded successfully',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      setState(() {
        _allowPop = true;
      });
      Navigator.pop(context);
    } else if (mounted) {
      final errorState = ref.read(documentationProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorState.uploadError ?? 'Failed to upload document',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<bool> _handleBack() async {
    if (_hasUnsavedChanges()) {
      final discard = await _showDiscardConfirmation();
      return discard ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final docState = ref.watch(documentationProvider);
    
    final partnerName = authState.user?.name ?? authState.user?.email ?? 'Metiss Partner';
    
    final formattedExecutedDate = _executedDate != null 
        ? DateFormat('MM/dd/yyyy').format(_executedDate!) 
        : '';
        
    final formattedEffectiveDate = _effectiveDate != null 
        ? DateFormat('MM/dd/yyyy').format(_effectiveDate!) 
        : '';

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && context.mounted) {
          setState(() {
            _allowPop = true;
          });
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            onPressed: () async {
              final shouldPop = await _handleBack();
              if (shouldPop && context.mounted) {
                setState(() {
                  _allowPop = true;
                });
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Add Document',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: const Color(0xFFDAE3E1),
              height: 1,
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      'Upload overall service agreement documents, contracts, and subscription terms.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.primaryColor.withValues(alpha: .7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Partner Name (Disabled)
                    _buildInputLabel('Partner Name'),
                    _buildDisabledTextField(partnerName),
                    const SizedBox(height: 20),

                    // Document Type Dropdown
                    _buildInputLabel('Document Type'),
                    _buildDropdown<String>(
                      value: _documentType,
                      hint: 'Select document type',
                      items: _docTypes,
                      onChanged: (val) {
                        setState(() {
                          _documentType = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Service Name Dropdown
                    _buildInputLabel('Service Name'),
                    _buildDropdown<String>(
                      value: _serviceName,
                      hint: 'Select service name',
                      items: _services,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _serviceName = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Executed Date Picker
                    _buildInputLabel('Executed Date'),
                    _buildDatePickerField(
                      valueText: formattedExecutedDate,
                      placeholder: 'Select executed date',
                      onTap: () => _selectDate(context, true),
                    ),
                    const SizedBox(height: 20),

                    // Effective Date Picker
                    _buildInputLabel('Effective Date'),
                    _buildDatePickerField(
                      valueText: formattedEffectiveDate,
                      placeholder: 'Select effective date',
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 20),

                    // Term Input
                    _buildInputLabel('Term'),
                    _buildTextField(
                      controller: _termController,
                      placeholder: 'Enter term (e.g. 12 Months)',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Status Dropdown
                    _buildInputLabel('Status'),
                    _buildDropdown<String>(
                      value: _status,
                      hint: 'Select status',
                      items: _statuses,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _status = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // File Picker
                    _buildInputLabel('Document File (PDF, Max 4MB)'),
                    const SizedBox(height: 6),
                    _buildFilePickerWidget(),
                    if (_fileError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _fileError!,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.red.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final shouldPop = await _handleBack();
                              if (shouldPop && context.mounted) {
                                setState(() {
                                  _allowPop = true;
                                });
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(LucideIcons.xCircle, size: 20),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: Color(0xFFDAE3E1)),
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isFormValid() ? _handleSave : null,
                            icon: const Icon(LucideIcons.save, size: 20),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFDAE3E1),
                              disabledForegroundColor: const Color(0xFFBBC2C0),
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (docState.isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDisabledTextField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFDAE3E1)),
      ),
      child: Text(
        value,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        filled: true,
        fillColor: AppTheme.inputBgColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      hint: Text(
        hint,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.primaryColor,
      ),
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.inputBgColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
    );
  }

  Widget _buildDatePickerField({
    required String valueText,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final hasValue = valueText.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: AppTheme.inputBgColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFDAE3E1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasValue ? valueText : placeholder,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: hasValue 
                    ? AppTheme.primaryColor 
                    : AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerWidget() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: AppTheme.primaryColor,
        borderRadius: 20.0,
        gap: 6.0,
        dashLength: 8.0,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.inputBgColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            if (_selectedFile != null) ...[
              const Icon(
                LucideIcons.fileText,
                size: 36,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedFileName ?? 'Selected File',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Size: ${_selectedFileSizeMb?.toStringAsFixed(2)} MB',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _removeFile,
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                LucideIcons.uploadCloud,
                size: 36,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload your Document',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(PDF file, Max 4MB)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: Color(0xFFDAE3E1)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Select PDF file to upload'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    this.color = const Color(0xFF01372C),
    this.strokeWidth = 1.2,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final length = dashLength;
        final start = distance;
        final end = distance + length;
        canvas.drawPath(
          pathMetric.extractPath(start, end),
          paint,
        );
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
