import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodels/auth_provider.dart';
import '../models/profile_model.dart';
import '../viewmodels/profile_provider.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isInitialized = false;
  bool _allowPop = false;
  String _communicationPreference = 'EMAIL';

  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.user?.email != null) {
        ref
            .read(profileProvider.notifier)
            .fetchProfile(authState.user!.email);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getInitials(String? firstName, String? lastName) {
    if (firstName == null && lastName == null) return 'U';
    final buffer = StringBuffer();
    if (firstName != null && firstName.trim().isNotEmpty) {
      buffer.write(firstName.trim()[0].toUpperCase());
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      buffer.write(lastName.trim()[0].toUpperCase());
    }
    final initials = buffer.toString();
    return initials.isEmpty ? 'U' : initials;
  }

  String _formatUsPhone(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '').substring(
      0,
      raw.replaceAll(RegExp(r'\D'), '').length > 10
          ? 10
          : raw.replaceAll(RegExp(r'\D'), '').length,
    );
    final length = digitsOnly.length;

    final area = digitsOnly.substring(0, length < 3 ? length : 3);
    final prefix = digitsOnly.substring(
      length < 3 ? length : 3,
      length < 6 ? length : 6,
    );
    final line = digitsOnly.substring(
      length < 6 ? length : 6,
      length < 10 ? length : 10,
    );

    if (digitsOnly.length <= 3) {
      return digitsOnly.isNotEmpty ? '($area' : '';
    }
    if (digitsOnly.length <= 6) {
      return '($area) $prefix'.trim();
    }
    return '($area) $prefix-$line'.trim();
  }

  bool _hasChanges(ProfileModel? profile) {
    if (profile == null) return false;
    final cleanFormPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final cleanProfilePhone = profile.phone.replaceAll(RegExp(r'\D'), '');

    return _firstNameController.text.trim() != profile.firstName.trim() ||
        _lastNameController.text.trim() != profile.lastName.trim() ||
        _jobTitleController.text.trim() != profile.jobTitle.trim() ||
        cleanFormPhone != cleanProfilePhone ||
        _communicationPreference != profile.communicationPreference;
  }

  bool _validate() {
    final errors = <String, String>{};
    if (_firstNameController.text.trim().isEmpty) {
      errors['firstName'] = 'First Name is required';
    }
    if (_lastNameController.text.trim().isEmpty) {
      errors['lastName'] = 'Last Name is required';
    }
    if (_jobTitleController.text.trim().isEmpty) {
      errors['jobTitle'] = 'Job Title is required';
    }

    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (_phoneController.text.trim().isEmpty) {
      errors['phone'] = 'Phone Number is required';
    } else if (rawPhone.length != 10) {
      errors['phone'] = 'Invalid phone format';
    }

    setState(() {
      _errors = errors;
    });

    return errors.isEmpty;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    final profileState = ref.read(profileProvider);
    if (profileState.profile == null) return;

    final currentProfile = profileState.profile!;
    final updatedProfile = currentProfile.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
      communicationPreference: _communicationPreference,
    );

    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(updatedProfile);

    if (success && mounted) {
      // Sync auth state
      ref.read(authProvider.notifier).updateUserInfo(
            firstName: updatedProfile.firstName,
            lastName: updatedProfile.lastName,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      setState(() {
        _isEditing = false;
        _isInitialized = false; // reload from updated state
        _errors = {};
        _allowPop = false;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileState.error ?? 'Failed to update profile',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _handleCancel() async {
    final profileState = ref.read(profileProvider);
    if (_hasChanges(profileState.profile)) {
      final discard = await _showDiscardConfirmation();
      if (discard != true) return;
    }
    setState(() {
      _isEditing = false;
      _isInitialized = false; // will reset controllers to original values
      _errors = {};
      _allowPop = false;
    });
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

  Future<bool> _handleBack() async {
    final profileState = ref.read(profileProvider);
    if (_isEditing && _hasChanges(profileState.profile)) {
      final discard = await _showDiscardConfirmation();
      return discard ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    if (!_isInitialized && profileState.profile != null) {
      final p = profileState.profile!;
      _firstNameController.text = p.firstName;
      _lastNameController.text = p.lastName;
      _jobTitleController.text = p.jobTitle;
      _emailController.text = p.email;
      _phoneController.text = _formatUsPhone(p.phone);
      _communicationPreference = p.communicationPreference;
      _isInitialized = true;
    }

    final initials = profileState.profile != null
        ? _getInitials(profileState.profile!.firstName, profileState.profile!.lastName)
        : 'U';

    return PopScope(
      canPop: _allowPop || !_isEditing || !_hasChanges(profileState.profile),
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
            'Profile',
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
        body: profileState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accentColor,
                  ),
                ),
              )
            : profileState.error != null && profileState.profile == null
                ? _buildErrorView(profileState.error!)
                : _buildProfileContent(initials, profileState),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade600,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load profile details',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF889492),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final authState = ref.read(authProvider);
                if (authState.user?.email != null) {
                  ref
                      .read(profileProvider.notifier)
                      .fetchProfile(authState.user!.email);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(String initials, ProfileState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Header
          Text(
            'Personal Information',
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
          const SizedBox(height: 24),

          // Avatar Row
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.accentColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Profile Image',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // First Name
          _buildProfileInput(
            label: 'First Name',
            controller: _firstNameController,
            isEditing: _isEditing,
            errorText: _errors['firstName'],
          ),
          const SizedBox(height: 20),

          // Last Name
          _buildProfileInput(
            label: 'Last Name',
            controller: _lastNameController,
            isEditing: _isEditing,
            errorText: _errors['lastName'],
          ),
          const SizedBox(height: 20),

          // Job Title
          _buildProfileInput(
            label: 'Job Title',
            controller: _jobTitleController,
            isEditing: _isEditing,
            errorText: _errors['jobTitle'],
          ),
          const SizedBox(height: 20),

          // Email (Read Only Override)
          _buildProfileInput(
            label: 'Email',
            controller: _emailController,
            isEditing: _isEditing,
            readOnlyOverride: true,
          ),
          const SizedBox(height: 20),

          // Phone Number
          _buildProfileInput(
            label: 'Phone Number',
            controller: _phoneController,
            isEditing: _isEditing,
            errorText: _errors['phone'],
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _PhoneInputFormatter(),
            ],
          ),
          const SizedBox(height: 20),

          // Communication Preference
          _buildPreferenceDropdown(
            label: 'Communication Preference',
            value: _communicationPreference,
            isEditing: _isEditing,
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _communicationPreference = val;
                });
              }
            },
          ),
          const SizedBox(height: 30),

          // Action Buttons
          if (state.isSaving)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            )
          else
            _buildActionButtons(),

          const SizedBox(height: 40),

          // Permissions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Permissions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Contact your system administrator to modify your permissions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            color: const Color(0xFFDAE3E1),
            height: 1,
            width: double.infinity,
          ),
          const SizedBox(height: 20),

          // Permissions Grid/List
          _buildPermissionsSection(state.profile?.permissions ?? []),
        ],
      ),
    );
  }

  Widget _buildProfileInput({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    bool readOnlyOverride = false,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final actualReadOnly = !isEditing || readOnlyOverride;

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
          readOnly: actualReadOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: actualReadOnly ? Colors.white : AppTheme.inputBgColor,
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

  Widget _buildPreferenceDropdown({
    required String label,
    required String value,
    required bool isEditing,
    required void Function(String?) onChanged,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: isEditing ? onChanged : null,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: !isEditing ? Colors.white : AppTheme.inputBgColor,
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
            disabledBorder: OutlineInputBorder(
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
          items: const [
            DropdownMenuItem(
              value: 'EMAIL',
              child: Text('Email'),
            ),
            DropdownMenuItem(
              value: 'TEXT_MESSAGE',
              child: Text('Text'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (!_isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
                _allowPop = false;
              });
            },
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _handleCancel,
          icon: const Icon(Icons.block_rounded, size: 20),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: const BorderSide(color: Color(0xFFDAE3E1)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _handleSave,
          icon: const Icon(Icons.save_rounded, size: 20),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009AE0),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(const Color(0xFF009AE0)),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection(List<String> userPermissions) {
    const list = [
      {
        'id': 'DEFAULT',
        'name': 'Default',
        'desc': 'Access to Home, Services, and Resources pages.'
      },
      {
        'id': 'BILLING',
        'name': 'Billing',
        'desc': 'View billing history and manage billing contact information'
      },
      {
        'id': 'DEVELOPMENT_CENTER',
        'name': 'Development Center',
        'desc': 'Manage API keys and documentation; Download Lightning App'
      },
      {
        'id': 'SUBSCRIPTION_SERVICES',
        'name': 'Subscription Services',
        'desc': 'View the lists of subscribed services and status of each'
      },
      {
        'id': 'ORGANIZATION',
        'name': 'Organization',
        'desc': 'Manage Organization profile and manage users and permissions'
      },
      {
        'id': 'CONFIGURATION',
        'name': 'Configurations',
        'desc': 'Manage global service settings and templates'
      },
    ];

    return Column(
      children: list.map((perm) {
        final isChecked =
            perm['id'] == 'DEFAULT' || userPermissions.contains(perm['id']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDAE3E1)),
                  color: isChecked ? AppTheme.accentColor : Colors.white,
                ),
                child: isChecked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perm['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      perm['desc']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
