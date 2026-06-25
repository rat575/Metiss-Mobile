import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/manual_registration_provider.dart';
import '../viewmodels/registration_provider.dart';
import 'add_assets_view.dart';
import 'registration_documents_view.dart';

class ContractedEnergyView extends ConsumerStatefulWidget {
  final List<SystemFormState> systems;
  final Map<String, dynamic> customerPayload;
  final Map<String, dynamic> sitePayload;
  final Map<String, dynamic>? equipmentCatalog;

  const ContractedEnergyView({
    super.key,
    required this.systems,
    required this.customerPayload,
    required this.sitePayload,
    required this.equipmentCatalog,
  });

  @override
  ConsumerState<ContractedEnergyView> createState() => _ContractedEnergyViewState();
}

class _ContractedEnergyViewState extends ConsumerState<ContractedEnergyView> {
  int _selectedSystemIndex = 0;
  late TextEditingController _numYearsController;
  Map<int, String> _yearErrors = {};
  bool _isSavingAndExiting = false;
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    _numYearsController = TextEditingController();
    _loadSystemData(_selectedSystemIndex);
  }

  @override
  void dispose() {
    _numYearsController.dispose();
    super.dispose();
  }

  void _loadSystemData(int index) {
    if (widget.systems.isEmpty) return;
    final sys = widget.systems[index];
    _numYearsController.text = sys.numYears != null ? sys.numYears.toString() : '';
    _yearErrors.clear();
  }

  void _onSystemChanged(int? newIndex) {
    if (newIndex == null || newIndex == _selectedSystemIndex) return;

    // First validate and save current system data
    if (_validateSystem(_selectedSystemIndex)) {
      setState(() {
        _selectedSystemIndex = newIndex;
        _loadSystemData(newIndex);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fix the errors in the current system before switching.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  bool _validateSystem(int index) {
    final sys = widget.systems[index];
    final errors = <int, String>{};
    bool isValid = true;

    if (sys.numYears != null && sys.numYears! > 0) {
      for (int i = 1; i <= sys.numYears!; i++) {
        final ctrl = sys.yearControllers[i];
        final valStr = ctrl?.text.trim() ?? '';
        if (valStr.isEmpty) {
          errors[i] = 'Required';
          isValid = false;
        } else {
          final val = double.tryParse(valStr);
          if (val == null || val < 0) {
            errors[i] = 'Min 0';
            isValid = false;
          }
        }
      }
    }

    if (index == _selectedSystemIndex) {
      setState(() {
        _yearErrors = errors;
      });
    }

    return isValid;
  }

  void _handleYearsChanged(String val) {
    final sys = widget.systems[_selectedSystemIndex];
    if (val.trim().isEmpty) {
      setState(() {
        sys.numYears = null;
        // Clean up controllers
        for (final ctrl in sys.yearControllers.values) {
          ctrl.dispose();
        }
        sys.yearControllers.clear();
        _yearErrors.clear();
      });
      return;
    }

    int? count = int.tryParse(val.trim());
    if (count == null || count < 0) return;
    if (count > 30) {
      count = 30;
      _numYearsController.text = '30';
      _numYearsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numYearsController.text.length),
      );
    }

    setState(() {
      sys.numYears = count;
      
      // Expand map if count increases
      for (int i = 1; i <= count!; i++) {
        sys.yearControllers.putIfAbsent(i, () => TextEditingController());
      }

      // Shrink map and dispose if count decreases
      if (count < sys.yearControllers.length) {
        final keysToRemove = sys.yearControllers.keys.where((k) => k > count!).toList();
        for (final k in keysToRemove) {
          sys.yearControllers.remove(k)?.dispose();
          _yearErrors.remove(k);
        }
      }
    });
  }

  DateTime? _toUtcStartOfDay(DateTime? date) {
    if (date == null) return null;
    return DateTime.utc(date.year, date.month, date.day, 0, 0, 0, 0);
  }

  Future<void> _handleSave({bool exitAfterSave = true}) async {
    // Validate all systems before finishing
    bool allValid = true;
    for (int i = 0; i < widget.systems.length; i++) {
      if (!_validateSystem(i)) {
        allValid = false;
        if (i != _selectedSystemIndex) {
          // Switch to the first system that has errors
          setState(() {
            _selectedSystemIndex = i;
            _loadSystemData(i);
          });
          break;
        }
      }
    }

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill out all required year fields correctly.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() {
      if (exitAfterSave) {
        _isSavingAndExiting = true;
      } else {
        _isSavingProgress = true;
      }
    });

    try {
      final systemsPayload = widget.systems.map((sys) {
        final contractedEnergyData = <Map<String, dynamic>>[];
        if (sys.numYears != null && sys.numYears! > 0) {
          for (int i = 1; i <= sys.numYears!; i++) {
            final ctrl = sys.yearControllers[i];
            final val = ctrl != null ? (double.tryParse(ctrl.text.trim()) ?? 0.0) : 0.0;
            contractedEnergyData.add({
              'year': i,
              'targetAnnual': val,
            });
          }
        }

        return {
          'uuid': sys.uuid ?? '',
          'organizationUuid': sys.organizationUuid ?? '',
          'name': sys.name,
          'size': sys.sizeController.text.trim(),
          'assetOwner': sys.ownerController.text.trim(),
          'installedBy': sys.installedByController.text.trim(),
          'status': sys.status,
          'installationDate': _toUtcStartOfDay(sys.installationDate)?.toIso8601String(),
          'activationDate': _toUtcStartOfDay(sys.activationDate)?.toIso8601String(),
          'monitoringStartDate': _toUtcStartOfDay(sys.monitoringStartDate)?.toIso8601String(),
          'assets': sys.buildAssetsMap(widget.equipmentCatalog),
          'contractedEnergy': contractedEnergyData,
        };
      }).toList();

      final payload = {
        'customer': widget.customerPayload,
        'site': widget.sitePayload,
        'system': systemsPayload,
      };

      final success = await ref
          .read(manualRegistrationProvider.notifier)
          .registerAsset(payload);

      if (success && mounted) {
        ref.invalidate(registrationListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Asset registered successfully',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        if (exitAfterSave) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        final state = ref.read(manualRegistrationProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.error ?? 'Failed to register asset',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAndExiting = false;
          _isSavingProgress = false;
        });
      }
    }
  }

  Widget _buildActionButtons(ManualRegistrationState state) {
    final showExitingLoader = state.isSaving && _isSavingAndExiting;
    final showProgressLoader = state.isSaving && _isSavingProgress;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: state.isSaving ? null : () => _handleSave(exitAfterSave: true),
            icon: showExitingLoader
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(LucideIcons.save, size: 20),
            label: showExitingLoader ? const Text('Saving...') : const Text('Save & Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFCACECE),
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isSaving ? null : () => Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.block_rounded, size: 20),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: Color(0xFFDAE3E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isSaving ? null : () => _handleSave(exitAfterSave: false),
                icon: showProgressLoader
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                        ),
                      )
                    : const Icon(LucideIcons.save, size: 20),
                label: showProgressLoader ? const Text('Saving...') : const Text('Save'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00C49C),
                  side: BorderSide(
                    color: !state.isSaving
                        ? const Color(0xFF00C49C)
                        : const Color(0xFFCACECE),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualRegistrationProvider);
    if (widget.systems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Asset Contracted Energy',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text('No systems available'),
        ),
      );
    }

    final sys = widget.systems[_selectedSystemIndex];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Asset Contracted Energy',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown: Select System
              _buildDropdownField(
                label: 'Select System',
                value: _selectedSystemIndex.toString(),
                items: List.generate(widget.systems.length, (idx) {
                  return DropdownMenuItem(
                    value: idx.toString(),
                    child: Text('System ${idx + 1}'),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    _onSystemChanged(int.parse(val));
                  }
                },
              ),
              const SizedBox(height: 20),

              // Text Field: # of Years
              _buildInputField(
                label: '# of Years',
                controller: _numYearsController,
                hintText: 'Enter # of Years',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _handleYearsChanged,
              ),
              const SizedBox(height: 32),

              // Dynamic Year Inputs Grid
              if (sys.numYears != null && sys.numYears! > 0) ...[
                Text(
                  'System ${_selectedSystemIndex + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const int columns = 3;
                    const double spacing = 12;
                    const double runSpacing = 16;

                    final int totalItems = sys.numYears!;
                    final int rowCount = (totalItems / columns).ceil();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(rowCount, (rowIndex) {
                        final int startIndex = rowIndex * columns;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: rowIndex == rowCount - 1 ? 0 : runSpacing,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(columns, (colIndex) {
                              final int itemIndex = startIndex + colIndex;
                              if (itemIndex >= totalItems) {
                                return const Expanded(child: SizedBox());
                              }

                              final year = itemIndex + 1;
                              final controller = sys.yearControllers[year]!;
                              final errorText = _yearErrors[year];

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: colIndex == columns - 1 ? 0 : spacing,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Year $year',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: controller,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                        ],
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppTheme.inputBgColor,
                                          hintText: '#',
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 10.0,
                                            horizontal: 12.0,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                            borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                            borderSide: const BorderSide(color: Color(0xFFDAE3E1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                            borderSide: const BorderSide(
                                              color: AppTheme.accentColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorText: errorText,
                                          errorStyle: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          if (val.trim().isNotEmpty) {
                                            setState(() {
                                              _yearErrors.remove(year);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),

              // Save & Cancel Buttons
              _buildActionButtons(state),
              const SizedBox(height: 16),

              // Asset Document Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationDocumentsView(
                                systems: widget.systems,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(LucideIcons.fileText, size: 20),
                  label: const Text('Asset document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.assetDocumentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCACECE),
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final hasValue = value != null && value.isNotEmpty && items.any((item) => item.value == value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: hasValue ? value : null,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppTheme.primaryColor,
            size: 24,
          ),
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
                color: AppTheme.accentColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.inputBgColor,
            hintText: hintText,
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
                color: AppTheme.accentColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
