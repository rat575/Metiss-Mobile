import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../models/registration_models.dart';
import '../viewmodels/manual_registration_provider.dart';
import '../viewmodels/registration_provider.dart';
import 'add_assets_view.dart';

class ManualRegistrationView extends ConsumerStatefulWidget {
  final RegistrationListEntry? editEntry;
  final String? openSystemName;

  const ManualRegistrationView({
    super.key,
    this.editEntry,
    this.openSystemName,
  });

  @override
  ConsumerState<ManualRegistrationView> createState() =>
      _ManualRegistrationViewState();
}

class _ManualRegistrationViewState
    extends ConsumerState<ManualRegistrationView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _siteAddressController = TextEditingController();
  final _secondAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _siteAddressFocus = FocusNode();

  bool _firstNameTouched = false;
  bool _lastNameTouched = false;
  bool _emailTouched = false;
  bool _phoneTouched = false;
  bool _siteAddressTouched = false;
  bool _cityTouched = false;
  bool _stateTouched = false;
  bool _zipCodeTouched = false;

  bool _isSavingAndExiting = false;
  bool _isSavingProgress = false;

  bool _isFormValid = false;

  Timer? _addressDebounce;
  bool _shouldFetchPredictions = true;

  @override
  void initState() {
    super.initState();

    if (widget.editEntry != null) {
      _firstNameController.text = widget.editEntry!.customer.firstName;
      _lastNameController.text = widget.editEntry!.customer.lastName;
      _emailController.text = widget.editEntry!.customer.email;
      _phoneController.text = widget.editEntry!.customer.phone ?? '';
      _siteAddressController.text = widget.editEntry!.site.siteAddress;
      _cityController.text = widget.editEntry!.site.city;
      _stateController.text = widget.editEntry!.site.state;
      _zipCodeController.text = widget.editEntry!.site.zipCode;

      _firstNameTouched = true;
      _lastNameTouched = true;
      _emailTouched = true;
      _phoneTouched = true;
      _siteAddressTouched = true;
      _cityTouched = true;
      _stateTouched = true;
      _zipCodeTouched = true;
    }
    
    // Add touched and validation listeners
    _firstNameFocus.addListener(() {
      if (!_firstNameFocus.hasFocus) {
        setState(() => _firstNameTouched = true);
      }
    });
    _firstNameController.addListener(() {
      if (_firstNameController.text.trim().isNotEmpty && !_firstNameTouched) {
        _firstNameTouched = true;
      }
      setState(() {});
      _updateFormState();
    });

    _lastNameFocus.addListener(() {
      if (!_lastNameFocus.hasFocus) {
        setState(() => _lastNameTouched = true);
      }
    });
    _lastNameController.addListener(() {
      if (_lastNameController.text.trim().isNotEmpty && !_lastNameTouched) {
        _lastNameTouched = true;
      }
      setState(() {});
      _updateFormState();
    });

    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        setState(() => _emailTouched = true);
      }
    });
    _emailController.addListener(() {
      if (_emailController.text.trim().isNotEmpty && !_emailTouched) {
        _emailTouched = true;
      }
      setState(() {});
      _updateFormState();
    });

    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) {
        setState(() => _phoneTouched = true);
      }
    });
    _phoneController.addListener(() {
      if (_phoneController.text.trim().isNotEmpty && !_phoneTouched) {
        _phoneTouched = true;
      }
      setState(() {});
      _updateFormState();
    });

    _siteAddressFocus.addListener(() {
      if (!_siteAddressFocus.hasFocus) {
        setState(() => _siteAddressTouched = true);
      }
    });
    _siteAddressController.addListener(_onAddressChanged);

    _secondAddressController.addListener(_updateFormState);
    _cityController.addListener(_updateFormState);
    _stateController.addListener(_updateFormState);
    _zipCodeController.addListener(_updateFormState);

    // Reset provider state on init
    Future.microtask(() {
      ref.read(manualRegistrationProvider.notifier).reset();
    });
    _updateFormState();
  }

  @override
  void dispose() {
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _siteAddressFocus.dispose();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _siteAddressController.dispose();
    _secondAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();

    _addressDebounce?.cancel();
    super.dispose();
  }

  void _updateFormState() {
    final newIsValid = _checkIsValid();
    if (newIsValid != _isFormValid) {
      setState(() {
        _isFormValid = newIsValid;
      });
    }
  }

  void _onAddressChanged() {
    if (_siteAddressController.text.trim().isNotEmpty && !_siteAddressTouched) {
      _siteAddressTouched = true;
    }
    
    // Clear dependent fields if the address query is emptied
    if (_siteAddressController.text.trim().isEmpty) {
      _cityController.text = '';
      _stateController.text = '';
      _zipCodeController.text = '';
      _siteAddressTouched = false;
      _cityTouched = false;
      _stateTouched = false;
      _zipCodeTouched = false;
    }

    setState(() {});

    _updateFormState();
    if (!_shouldFetchPredictions) return;

    final query = _siteAddressController.text;
    if (_addressDebounce?.isActive ?? false) _addressDebounce!.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(manualRegistrationProvider.notifier)
          .fetchAddressPredictions(query);
    });
  }

  bool _checkIsValid() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final zipRegex = RegExp(r'^\d{5}(?:-\d{4})?$');

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final siteAddress = _siteAddressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final zipCode = _zipCodeController.text.trim();

    if (firstName.isEmpty) return false;
    if (lastName.isEmpty) return false;
    if (email.isEmpty || !emailRegex.hasMatch(email)) return false;
    if (phone.isNotEmpty && phone.length < 10) return false;
    if (siteAddress.isEmpty) return false;
    if (city.isEmpty) return false;
    if (state.isEmpty) return false;
    if (zipCode.isEmpty || !zipRegex.hasMatch(zipCode)) return false;

    return true;
  }

  String? _getFirstNameError() {
    if (!_firstNameTouched) return null;
    final text = _firstNameController.text.trim();
    if (text.isEmpty) return 'First name is required';
    return null;
  }

  String? _getLastNameError() {
    if (!_lastNameTouched) return null;
    final text = _lastNameController.text.trim();
    if (text.isEmpty) return 'Last name is required';
    return null;
  }

  String? _getEmailError() {
    if (!_emailTouched) return null;
    final text = _emailController.text.trim();
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(text)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _getPhoneError() {
    final text = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (text.isEmpty) return null;
    if (!_phoneTouched) return null;
    if (text.length < 10) {
      return 'Invalid phone format (must be 10 digits)';
    }
    return null;
  }

  String? _getSiteAddressError() {
    if (!_siteAddressTouched) return null;
    final text = _siteAddressController.text.trim();
    if (text.isEmpty) return 'Street address is required';
    return null;
  }

  String? _getCityError() {
    if (!_cityTouched) return null;
    final text = _cityController.text.trim();
    if (text.isEmpty) return 'City is required';
    return null;
  }

  String? _getStateError() {
    if (!_stateTouched) return null;
    final text = _stateController.text.trim();
    if (text.isEmpty) return 'State is required';
    return null;
  }

  String? _getZipError() {
    if (!_zipCodeTouched) return null;
    final text = _zipCodeController.text.trim();
    if (text.isEmpty) return 'Zip code is required';
    final zipRegex = RegExp(r'^\d{5}(?:-\d{4})?$');
    if (!zipRegex.hasMatch(text)) {
      return 'Invalid ZIP code format';
    }
    return null;
  }

  Future<void> _handlePredictionClick(dynamic prediction) async {
    final placeId = prediction['place_id'] as String? ?? '';
    final description = prediction['description'] as String? ?? '';

    ref.read(manualRegistrationProvider.notifier).clearPredictions();

    final result = await ref
        .read(manualRegistrationProvider.notifier)
        .fetchPlaceDetails(placeId, description);

    if (result != null && mounted) {
      final components = result['address_components'] as List? ?? [];

      String? getComponent(String type, {bool useShort = false}) {
        for (final comp in components) {
          final types = comp['types'] as List? ?? [];
          if (types.contains(type)) {
            return useShort ? comp['short_name'] : comp['long_name'];
          }
        }
        return null;
      }

      final streetNumber = getComponent('street_number') ?? '';
      final route = getComponent('route') ?? '';
      final locality =
          getComponent('locality') ?? getComponent('sublocality') ?? '';
      final state =
          getComponent('administrative_area_level_1', useShort: true) ?? '';
      final postalCode = getComponent('postal_code') ?? '';

      final fullStreet = [
        streetNumber,
        route,
      ].where((s) => s.isNotEmpty).join(' ');

      setState(() {
        _shouldFetchPredictions = false;
        _siteAddressController.text = fullStreet;
        _secondAddressController.text = '';
        _cityController.text = locality;
        _stateController.text = state.toUpperCase();
        _zipCodeController.text = postalCode;

        // Mark address fields as touched
        _siteAddressTouched = true;
        _cityTouched = true;
        _stateTouched = true;
        _zipCodeTouched = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shouldFetchPredictions = true;
        _updateFormState();
      });
    }
  }

  void _handleNavigateToAddAssets() {
    setState(() {
      _firstNameTouched = true;
      _lastNameTouched = true;
      _emailTouched = true;
      _phoneTouched = true;
      _siteAddressTouched = true;
      _cityTouched = true;
      _stateTouched = true;
      _zipCodeTouched = true;
    });

    _updateFormState();
    if (!_checkIsValid()) return;

    final customerPayload = {
      'uuid': widget.editEntry?.customer.uuid ?? '',
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.replaceAll(RegExp(r'\D'), ''),
    };

    final sitePayload = {
      'uuid': widget.editEntry?.site.uuid ?? '',
      'organizationUuid': widget.editEntry?.system.firstOrNull?.organizationUuid ?? '',
      'siteAddress': _siteAddressController.text.trim(),
      'secondAddress': _secondAddressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zipCode': _zipCodeController.text.trim(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAssetsView(
          customerPayload: customerPayload,
          sitePayload: sitePayload,
          initialSystems: widget.editEntry?.system,
          openSystemName: widget.openSystemName,
        ),
      ),
    );
  }

  Future<void> _handleSave({bool exitAfterSave = true}) async {
    if (!_checkIsValid()) return;

    setState(() {
      if (exitAfterSave) {
        _isSavingAndExiting = true;
      } else {
        _isSavingProgress = true;
      }
    });

    try {
      final payload = {
        'customer': {
          'uuid': widget.editEntry?.customer.uuid ?? '',
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        },
        'site': {
          'uuid': widget.editEntry?.site.uuid ?? '',
          'organizationUuid': widget.editEntry?.system.firstOrNull?.organizationUuid ?? '',
          'siteAddress': _siteAddressController.text.trim(),
          'secondAddress': _secondAddressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zipCode': _zipCodeController.text.trim(),
        },
        'system': widget.editEntry?.system.map((sys) => sys.toJson()).toList() ?? [],
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
        }
      } else if (mounted) {
        final state = ref.read(manualRegistrationProvider);
        _showTopLeftToast(
          context,
          state.error ?? 'Failed to register asset',
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualRegistrationProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manual Registration',
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
              // Customer Details Header
              Text(
                'Customer Registration',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                color: const Color(0xFFDAE3E1),
                height: 1,
                width: double.infinity,
              ),
              const SizedBox(height: 20),

              // First Name
              _buildInputField(
                label: 'First Name',
                controller: _firstNameController,
                hintText: 'Enter first name',
                focusNode: _firstNameFocus,
                errorText: _getFirstNameError(),
              ),
              const SizedBox(height: 20),

              // Last Name
              _buildInputField(
                label: 'Last Name',
                controller: _lastNameController,
                hintText: 'Enter last name',
                focusNode: _lastNameFocus,
                errorText: _getLastNameError(),
              ),
              const SizedBox(height: 20),

              // Email
              _buildInputField(
                label: 'Email',
                controller: _emailController,
                hintText: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocus,
                errorText: _getEmailError(),
              ),
              const SizedBox(height: 20),

              // Mobile Phone
              _buildInputField(
                label: 'Mobile Phone (Optional)',
                controller: _phoneController,
                hintText: 'Enter mobile phone',
                keyboardType: TextInputType.phone,
                focusNode: _phoneFocus,
                errorText: _getPhoneError(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _PhoneInputFormatter(),
                ],
              ),
              const SizedBox(height: 32),

              // Site Details Header
              Text(
                'Site Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                color: const Color(0xFFDAE3E1),
                height: 1,
                width: double.infinity,
              ),
              const SizedBox(height: 20),

              // Site Street Address
              _buildInputField(
                label: 'Site Street Address',
                controller: _siteAddressController,
                hintText: 'Enter street address',
                focusNode: _siteAddressFocus,
                errorText: _getSiteAddressError(),
                suffixIcon:
                    state.isFetchingPredictions || state.isFetchingDetails
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentColor,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),

              // Address Suggestions dropdown/overlay container
              if (state.predictions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDAE3E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.predictions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFFE5E8E7), height: 1),
                    itemBuilder: (context, index) {
                      final prediction = state.predictions[index];
                      final description =
                          prediction['description'] as String? ?? '';
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.accentColor,
                        ),
                        title: Text(
                          description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        onTap: () => _handlePredictionClick(prediction),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // 2nd Address
              _buildInputField(
                label: '2nd Address (Optional)',
                controller: _secondAddressController,
                hintText: 'Suite, unit, building, etc.',
              ),
              const SizedBox(height: 20),

              // City
              _buildInputField(
                label: 'City',
                controller: _cityController,
                hintText: 'City',
                readOnly: true,
                errorText: _getCityError(),
              ),
              const SizedBox(height: 20),

              // State
              _buildInputField(
                label: 'State',
                controller: _stateController,
                hintText: 'State',
                readOnly: true,
                errorText: _getStateError(),
              ),
              const SizedBox(height: 20),

              // Zip Code
              _buildInputField(
                label: 'Zip Code',
                controller: _zipCodeController,
                hintText: 'Zip Code',
                readOnly: true,
                errorText: _getZipError(),
              ),
              const SizedBox(height: 40),

              // Save & Cancel Buttons
              _buildActionButtons(state),

              const SizedBox(height: 16),

              // Add Assets Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFormValid && !state.isSaving ? _handleNavigateToAddAssets : null,
                  icon: const Icon(LucideIcons.plusCircle, size: 20),
                  label: const Text('Add Assets'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C49C),
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
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(const Color(0xFF00C49C)),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    FocusNode? focusNode,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool readOnly = false,
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
          focusNode: focusNode,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.white : AppTheme.inputBgColor,
            hintText: hintText,
            suffixIcon: suffixIcon,
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
            errorText: errorText,
            errorStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ManualRegistrationState state) {
    final showExitingLoader = state.isSaving && _isSavingAndExiting;
    final showProgressLoader = state.isSaving && _isSavingProgress;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isFormValid && !state.isSaving ? () => _handleSave(exitAfterSave: true) : null,
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
              minimumSize: const Size(0, 44),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(0, 42),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isFormValid && !state.isSaving ? () => _handleSave(exitAfterSave: false) : null,
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
                    color: (_isFormValid && !state.isSaving)
                        ? const Color(0xFF00C49C)
                        : const Color(0xFFCACECE),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(0, 42),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    final length = digitsOnly.length;
    final sliced = length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

    final area = sliced.substring(0, sliced.length < 3 ? sliced.length : 3);
    final prefix = sliced.substring(
      sliced.length < 3 ? sliced.length : 3,
      sliced.length < 6 ? sliced.length : 6,
    );
    final line = sliced.substring(
      sliced.length < 6 ? sliced.length : 6,
      sliced.length < 10 ? sliced.length : 10,
    );

    String formatted;
    if (sliced.isEmpty) {
      formatted = '';
    } else if (sliced.length <= 3) {
      formatted = '($area';
    } else if (sliced.length <= 6) {
      formatted = '($area) $prefix';
    } else {
      formatted = '($area) $prefix-$line';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

void _showTopLeftToast(BuildContext context, String message, {bool isError = true}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: _ToastWidget(
          message: message,
          isError: isError,
          onDismiss: () {
            overlayEntry.remove();
          },
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Start dismissal timer
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isError ? Colors.red.shade600 : AppTheme.accentColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.message,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
