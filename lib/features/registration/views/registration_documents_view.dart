import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import 'add_assets_view.dart';

class RegistrationDocumentsView extends StatefulWidget {
  final List<SystemFormState> systems;

  const RegistrationDocumentsView({super.key, required this.systems});

  @override
  State<RegistrationDocumentsView> createState() =>
      _RegistrationDocumentsViewState();
}

class _RegistrationDocumentsViewState extends State<RegistrationDocumentsView> {
  String _selectedSystemFilter = 'ALL'; // 'ALL' or index of system
  bool _showAddForm = false;

  // Form states
  SystemFormState? _selectedSystemForDoc;
  final _docNameController = TextEditingController();
  String? _docType;
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileType;
  String? _selectedFileBase64;
  double? _selectedFileSizeMb;
  String? _fileError;

  final List<Map<String, String>> _docTypes = [
    {'label': 'Design', 'value': 'DESIGN'},
    {'label': 'Permit', 'value': 'PERMIT'},
    {'label': 'Customer Contract', 'value': 'CUSTOMER_CONTRACT'},
    {'label': 'Utility', 'value': 'UTILITY'},
    {'label': 'Photos', 'value': 'PHOTOS'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.systems.isNotEmpty) {
      _selectedSystemForDoc = widget.systems[0];
    }
  }

  @override
  void dispose() {
    _docNameController.dispose();
    super.dispose();
  }

  String _getDocTypeLabel(String val) {
    final type = _docTypes.firstWhere(
      (t) => t['value'] == val,
      orElse: () => {'label': val},
    );
    return type['label']!;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
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
            _selectedFileType = null;
            _selectedFileBase64 = null;
            _selectedFileSizeMb = null;
          });
          return;
        }

        final bytes = await file.readAsBytes();
        final base64Content = base64Encode(bytes);
        final ext = path.split('.').last.toUpperCase();

        setState(() {
          _fileError = null;
          _selectedFile = file;
          _selectedFileName = result.files.single.name;
          _selectedFileType = ext == 'JPEG' ? 'JPG' : ext;
          _selectedFileBase64 = base64Content;
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
      _selectedFileType = null;
      _selectedFileBase64 = null;
      _selectedFileSizeMb = null;
      _fileError = null;
    });
  }

  bool _isFormValid() {
    return _selectedSystemForDoc != null &&
        _docNameController.text.trim().isNotEmpty &&
        _docType != null &&
        _selectedFile != null &&
        _selectedFileBase64 != null;
  }

  void _saveDocument() {
    if (!_isFormValid()) return;

    final newDoc = SystemDocumentFormState(
      name: _docNameController.text.trim(),
      type: _docType!,
      fileName: _selectedFileName!,
      fileType: _selectedFileType!,
      base64Content: _selectedFileBase64!,
      filePath: _selectedFile!.path,
      uploadedDate: DateTime.now().toIso8601String(),
    );

    setState(() {
      _selectedSystemForDoc!.documents.add(newDoc);
      _showAddForm = false;
      _resetForm();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Document added locally. Remember to click Save on the Systems page to persist.',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  void _resetForm() {
    _docNameController.clear();
    _docType = null;
    _selectedFile = null;
    _selectedFileName = null;
    _selectedFileType = null;
    _selectedFileBase64 = null;
    _selectedFileSizeMb = null;
    _fileError = null;
  }

  void _deleteDocument(SystemFormState sys, SystemDocumentFormState doc) {
    setState(() {
      sys.documents.remove(doc);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Document deleted locally',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  Future<void> _viewDocument(SystemDocumentFormState doc) async {
    if (doc.signedUrl != null && doc.signedUrl!.isNotEmpty) {
      final uri = Uri.parse(doc.signedUrl!);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch ${doc.signedUrl}';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open document link.',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This document is stored locally and will be available after you save the system registration.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredDocuments() {
    final list = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.systems.length; i++) {
      final sys = widget.systems[i];
      if (_selectedSystemFilter != 'ALL' &&
          _selectedSystemFilter != i.toString()) {
        continue;
      }
      for (final doc in sys.documents) {
        list.add({'system': sys, 'document': doc});
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocs = _getFilteredDocuments();

    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 40),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'System Asset Documents',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Description
              Text(
                'Upload site- or asset-level documents for each registered system, such as designs, permits, contracts, or photos.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.primaryColor.withValues(alpha: .7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Top Buttons & Filter
              if (!_showAddForm) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'System Documents',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAddForm = true;
                        });
                      },
                      icon: const Icon(LucideIcons.plusCircle, size: 16),
                      label: const Text('Add Document'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter Dropdown
                _buildFilterDropdown(),
                const SizedBox(height: 20),

                // Documents List
                if (filteredDocs.isEmpty)
                  _buildEmptyView()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < filteredDocs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        _buildDocumentCard(
                          filteredDocs[i]['system'] as SystemFormState,
                          filteredDocs[i]['document'] as SystemDocumentFormState,
                        ),
                      ],
                    ],
                  ),
              ] else ...[
                // Inline Add Document Form
                _buildAddDocumentForm(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'ALL', child: Text('All Systems')),
    ];
    for (int i = 0; i < widget.systems.length; i++) {
      items.add(
        DropdownMenuItem(
          value: i.toString(),
          child: Text(widget.systems[i].name),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDAE3E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSystemFilter,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primaryColor,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedSystemFilter = val;
              });
            }
          },
          items: items,
        ),
      ),
    );
  }

  Widget _buildDocumentCard(SystemFormState sys, SystemDocumentFormState doc) {
    final typeLabel = _getDocTypeLabel(doc.type);
    final isPdf = doc.fileType.toUpperCase() == 'PDF';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDAE3E1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.inputBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPdf ? LucideIcons.fileText : LucideIcons.image,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'System: ${sys.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Document type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'File: ${doc.fileName} (${doc.fileType})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF889492),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewDocument(doc),
                  icon: const Icon(LucideIcons.eye, size: 14),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: Color(0xFFDAE3E1)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteDocument(sys, doc),
                  icon: const Icon(LucideIcons.trash2, size: 14),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDAE3E1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.folderOpen,
            size: 44,
            color: Color(0xFFDAE3E1),
          ),
          const SizedBox(height: 16),
          Text(
            'No documents for this selection',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF889492),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap Add Document to upload a file',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFFBBC2C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDocumentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add System Document',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _showAddForm = false;
                  _resetForm();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFDAE3E1), height: 1),
        const SizedBox(height: 24),

        // System Selector
        _buildLabel('Select System'),
        _buildSystemDropdown(),
        const SizedBox(height: 16),

        // Document Name
        _buildLabel('Document Name'),
        _buildTextField(_docNameController, 'Enter document name'),
        const SizedBox(height: 16),

        // Document Type
        _buildLabel('Document Type'),
        _buildTypeDropdown(),
        const SizedBox(height: 20),

        // File Selector
        _buildLabel('File (PDF, JPG, PNG under 4MB)'),
        const SizedBox(height: 6),
        _buildFileSelectorWidget(),
        if (_fileError != null) ...[
          const SizedBox(height: 6),
          Text(
            _fileError!,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.red.shade600,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Save & Cancel
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: Color(0xFFDAE3E1)),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isFormValid() ? _saveDocument : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFDAE3E1),
                  disabledForegroundColor: const Color(0xFFBBC2C0),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSystemDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.inputBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDAE3E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SystemFormState>(
          value: _selectedSystemForDoc,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primaryColor,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedSystemForDoc = val;
              });
            }
          },
          items: widget.systems.map((sys) {
            return DropdownMenuItem(value: sys, child: Text(sys.name));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.inputBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDAE3E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _docType,
          hint: Text(
            'Select document type',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primaryColor,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _docType = val;
              });
            }
          },
          items: _docTypes.map((t) {
            return DropdownMenuItem(
              value: t['value'],
              child: Text(t['label']!),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        filled: true,
        fillColor: AppTheme.inputBgColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
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

  Widget _buildFileSelectorWidget() {
    final hasFile = _selectedFile != null;

    return CustomPaint(
      painter: DashedBorderPainter(
        color: AppTheme.primaryColor,
        borderRadius: 16.0,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.inputBgColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (hasFile) ...[
              const Icon(
                LucideIcons.fileText,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 10),
              Text(
                _selectedFileName ?? 'File',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Size: ${_selectedFileSizeMb?.toStringAsFixed(2)} MB ($_selectedFileType)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _removeFile,
                icon: const Icon(LucideIcons.trash2, size: 14),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                LucideIcons.uploadCloud,
                size: 32,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 10),
              Text(
                'Select File',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(PDF, JPG, PNG up to 4MB)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(0, 32),
                  side: const BorderSide(color: Color(0xFFDAE3E1)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Choose file to upload'),
              ),
            ],
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
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final length = dashLength;
        final start = distance;
        final end = distance + length;
        canvas.drawPath(pathMetric.extractPath(start, end), paint);
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
