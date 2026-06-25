import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/registration_models.dart';
import '../repositories/registration_repository_provider.dart';
import '../viewmodels/manual_registration_provider.dart';
import '../viewmodels/registration_provider.dart';
import 'contracted_energy_view.dart';
import 'registration_documents_view.dart';

class InverterFormState {
  final manufacturerController = TextEditingController();
  final modelController = TextEditingController();
  final sizeController = TextEditingController();
  final serialController = TextEditingController();

  bool manufacturerTouched = false;
  bool modelTouched = false;
  bool sizeTouched = false;
  bool serialTouched = false;

  void dispose() {
    manufacturerController.dispose();
    modelController.dispose();
    sizeController.dispose();
    serialController.dispose();
  }

  bool isValid(List? inverterCatalog) {
    if (manufacturerController.text.trim().isEmpty) return false;
    if (modelController.text.trim().isEmpty) return false;
    if (sizeController.text.trim().isEmpty) return false;
    if (serialController.text.trim().isEmpty) return false;

    final rule = getSizeValidation(
      inverterCatalog,
      manufacturerController.text.trim(),
      modelController.text.trim(),
    );
    final sizeErr = validateSize(sizeController.text, rule, 'Size');
    return sizeErr == null;
  }
}

class StorageFormState {
  final manufacturerController = TextEditingController();
  final modelController = TextEditingController();
  final sizeController = TextEditingController();
  final serialController = TextEditingController();

  bool manufacturerTouched = false;
  bool modelTouched = false;
  bool sizeTouched = false;
  bool serialTouched = false;

  void dispose() {
    manufacturerController.dispose();
    modelController.dispose();
    sizeController.dispose();
    serialController.dispose();
  }

  bool isValid(List? storageCatalog) {
    if (manufacturerController.text.trim().isEmpty) return false;
    if (modelController.text.trim().isEmpty) return false;
    if (sizeController.text.trim().isEmpty) return false;
    if (serialController.text.trim().isEmpty) return false;

    final rule = getSizeValidation(
      storageCatalog,
      manufacturerController.text.trim(),
      modelController.text.trim(),
    );
    final sizeErr = validateSize(sizeController.text, rule, 'Size');
    return sizeErr == null;
  }
}

List<String> getManufacturers(List<dynamic>? catalog) {
  if (catalog == null) return [];
  return catalog
      .map((m) => m['manufacturerName'] as String? ?? '')
      .where((name) => name.isNotEmpty)
      .toList()
    ..sort();
}

List<String> getSeriesForManufacturer(List<dynamic>? catalog, String manufacturerName) {
  if (catalog == null || manufacturerName.isEmpty) return [];
  final mfg = catalog.firstWhere(
    (m) => (m['manufacturerName'] as String? ?? '').toLowerCase() == manufacturerName.toLowerCase(),
    orElse: () => null,
  );
  if (mfg == null) return [];
  final seriesList = mfg['series'] as List? ?? [];
  return seriesList
      .map((s) => s['name'] as String? ?? '')
      .where((name) => name.isNotEmpty)
      .toList()
    ..sort();
}

Map<String, double?> getWattageRange(List<dynamic>? catalog, String manufacturerName, String seriesName) {
  if (catalog == null || manufacturerName.isEmpty || seriesName.isEmpty) return {};
  final mfg = catalog.firstWhere(
    (m) => (m['manufacturerName'] as String? ?? '').toLowerCase() == manufacturerName.toLowerCase(),
    orElse: () => null,
  );
  if (mfg == null) return {};
  final seriesList = mfg['series'] as List? ?? [];
  final series = seriesList.firstWhere(
    (s) => (s['name'] as String? ?? '').toLowerCase() == seriesName.toLowerCase(),
    orElse: () => null,
  );
  if (series == null) return {};
  
  final minVal = series['min'] != null ? double.tryParse(series['min'].toString()) : null;
  final maxVal = series['max'] != null ? double.tryParse(series['max'].toString()) : null;
  return {'min': minVal, 'max': maxVal};
}

class SizeValidationRule {
  final String type; // 'array', 'range', or 'none'
  final List<String> values;
  final double? min;
  final double? max;

  SizeValidationRule({
    required this.type,
    this.values = const [],
    this.min,
    this.max,
  });
}

SizeValidationRule getSizeValidation(List<dynamic>? catalog, String manufacturerName, String seriesName) {
  if (catalog == null || manufacturerName.isEmpty || seriesName.isEmpty) {
    return SizeValidationRule(type: 'none');
  }
  try {
    final mfg = catalog.firstWhere(
      (m) => (m['manufacturerName'] as String? ?? '').toLowerCase() == manufacturerName.toLowerCase(),
      orElse: () => null,
    );
    if (mfg == null) return SizeValidationRule(type: 'none');
    final seriesList = mfg['series'] as List? ?? [];
    final series = seriesList.firstWhere(
      (s) => (s['name'] as String? ?? '').toLowerCase() == seriesName.toLowerCase(),
      orElse: () => null,
    );
    if (series == null) return SizeValidationRule(type: 'none');

    final sizeArray = series['size'] as List?;
    if (sizeArray != null && sizeArray.isNotEmpty) {
      return SizeValidationRule(
        type: 'array',
        values: sizeArray.map((e) => e.toString()).toList(),
      );
    }

    final minSize = series['minSize'] != null ? double.tryParse(series['minSize'].toString()) : null;
    final maxSize = series['maxSize'] != null ? double.tryParse(series['maxSize'].toString()) : null;
    if (minSize != null && maxSize != null) {
      return SizeValidationRule(
        type: 'range',
        min: minSize,
        max: maxSize,
      );
    }
  } catch (_) {}
  return SizeValidationRule(type: 'none');
}

String? validateSize(String text, SizeValidationRule rule, String label) {
  final cleanText = text.trim();
  if (cleanText.isEmpty) {
    return '$label is required';
  }
  if (rule.type == 'array') {
    final numVal = double.tryParse(cleanText);
    final isValid = rule.values.any((v) => double.tryParse(v) == numVal);
    if (!isValid) {
      return '$label must be one of: ${rule.values.join(', ')}';
    }
  } else if (rule.type == 'range' && rule.min != null && rule.max != null) {
    final numVal = double.tryParse(cleanText);
    if (numVal == null || numVal < rule.min! || numVal > rule.max!) {
      return '$label must be between ${rule.min!.toStringAsFixed(0)} and ${rule.max!.toStringAsFixed(0)}';
    }
  }
  return null;
}

class SystemDocumentFormState {
  String? uuid;
  String name;
  String type; // 'DESIGN', 'PERMIT', 'CUSTOMER_CONTRACT', 'UTILITY', 'PHOTOS'
  String fileName;
  String fileType; // 'PDF', 'PNG', 'JPG'
  String base64Content;
  String? uploadedDate;
  String? filePath;
  String? signedUrl;

  SystemDocumentFormState({
    this.uuid,
    required this.name,
    required this.type,
    required this.fileName,
    required this.fileType,
    required this.base64Content,
    this.uploadedDate,
    this.filePath,
    this.signedUrl,
  });
}

class SystemFormState {
  String name;
  final TextEditingController sizeController;
  final TextEditingController ownerController;
  final TextEditingController installedByController;
  String status; // 'ACTIVE' or 'INACTIVE'
  DateTime? installationDate;
  DateTime? activationDate;
  DateTime? monitoringStartDate;
  bool isExpanded;
  final List<SystemDocumentFormState> documents = [];

  // Touch flags for validation
  bool sizeTouched = false;
  bool ownerTouched = false;
  bool installedByTouched = false;
  bool installationDateTouched = false;
  bool activationDateTouched = false;
  bool monitoringStartDateTouched = false;

  // Collapsible Asset Details
  bool showAssetsSection = false;

  // Panels Details
  bool panelsEnabled = false;
  final panelManufacturerController = TextEditingController();
  final panelSeriesController = TextEditingController();
  final panelWattageController = TextEditingController();
  final panelCountController = TextEditingController();
  bool panelManufacturerTouched = false;
  bool panelSeriesTouched = false;
  bool panelWattageTouched = false;
  bool panelCountTouched = false;

  // Inverter Details
  bool invertersEnabled = false;
  final inverterCountController = TextEditingController();
  final List<InverterFormState> inverters = [];

  // Storage Details
  bool storagesEnabled = false;
  final storageCountController = TextEditingController();
  final List<StorageFormState> storages = [];

  // Contracted Energy Details
  int? numYears;
  final Map<int, TextEditingController> yearControllers = {};

  String? uuid;
  String? organizationUuid;

  SystemFormState({
    required this.name,
    this.status = 'ACTIVE',
    this.installationDate,
    this.activationDate,
    this.monitoringStartDate,
    this.isExpanded = true,
    this.uuid,
    this.organizationUuid,
  })  : sizeController = TextEditingController(),
        ownerController = TextEditingController(),
        installedByController = TextEditingController();

  void dispose() {
    sizeController.dispose();
    ownerController.dispose();
    installedByController.dispose();
    panelManufacturerController.dispose();
    panelSeriesController.dispose();
    panelWattageController.dispose();
    panelCountController.dispose();
    inverterCountController.dispose();
    for (final inv in inverters) {
      inv.dispose();
    }
    storageCountController.dispose();
    for (final stor in storages) {
      stor.dispose();
    }
    for (final ctrl in yearControllers.values) {
      ctrl.dispose();
    }
  }

  bool checkIsValid(Map<String, dynamic>? catalog) {
    if (sizeController.text.trim().isEmpty) return false;
    if (ownerController.text.trim().isEmpty) return false;
    if (installedByController.text.trim().isEmpty) return false;
    if (installationDate == null) return false;
    if (activationDate == null) return false;
    if (monitoringStartDate == null) return false;

    if (showAssetsSection) {
      final panelsCatalog = catalog?['panels'] as List?;
      final invertersCatalog = catalog?['inverters'] as List?;
      final storagesCatalog = catalog?['storages'] as List?;

      if (panelsEnabled && !isPanelDetailsFilled(panelsCatalog)) return false;
      if (invertersEnabled && !isInvertersFilled(invertersCatalog)) return false;
      if (storagesEnabled && !isStoragesFilled(storagesCatalog)) return false;
      if (!hasValidAssetCombination(catalog)) return false;
    }

    return true;
  }

  bool isPanelDetailsFilled(List? catalog) {
    if (!panelsEnabled) return false;
    if (panelManufacturerController.text.trim().isEmpty) return false;
    if (panelSeriesController.text.trim().isEmpty) return false;
    if (panelWattageController.text.trim().isEmpty) return false;

    final range = getWattageRange(
      catalog,
      panelManufacturerController.text,
      panelSeriesController.text,
    );
    final wattageVal = double.tryParse(panelWattageController.text.trim());
    if (wattageVal == null) return false;
    if (range['min'] != null && range['max'] != null) {
      if (wattageVal < range['min']! || wattageVal > range['max']!) return false;
    }

    final count = int.tryParse(panelCountController.text.trim());
    if (count == null || count <= 0) return false;
    return true;
  }

  bool isInvertersFilled(List? inverterCatalog) {
    if (!invertersEnabled) return false;
    final count = int.tryParse(inverterCountController.text.trim());
    if (count == null || count <= 0) return false;
    if (inverters.length < count) return false;
    for (final inv in inverters) {
      if (!inv.isValid(inverterCatalog)) return false;
    }
    return true;
  }

  bool isStoragesFilled(List? storageCatalog) {
    if (!storagesEnabled) return false;
    final count = int.tryParse(storageCountController.text.trim());
    if (count == null || count <= 0) return false;
    if (storages.length < count) return false;
    for (final stor in storages) {
      if (!stor.isValid(storageCatalog)) return false;
    }
    return true;
  }

  bool hasValidAssetCombination(Map<String, dynamic>? catalog) {
    if (!showAssetsSection) return true;
    if (!panelsEnabled && !invertersEnabled && !storagesEnabled) return false;

    final hasPanels = isPanelDetailsFilled(catalog?['panels'] as List?);
    final hasInverters = isInvertersFilled(catalog?['inverters'] as List?);
    final hasStorage = isStoragesFilled(catalog?['storages'] as List?);

    if (hasPanels && hasInverters && !hasStorage) return true;
    if (hasPanels && !hasInverters && hasStorage) return true;
    if (hasPanels && hasInverters && hasStorage) return true;
    if (!hasPanels && !hasInverters && hasStorage) return true;

    return false;
  }

  Map<String, dynamic> buildAssetsMap(Map<String, dynamic>? catalog) {
    final Map<String, dynamic> assets = {};

    if (showAssetsSection && panelsEnabled && isPanelDetailsFilled(catalog?['panels'] as List?)) {
      assets['panels'] = [
        {
          'type': 'PANEL',
          'details': {
            'manufacturer': panelManufacturerController.text.trim(),
            'series': panelSeriesController.text.trim(),
            'wattage': panelWattageController.text.trim(),
            'noOfPanels': int.tryParse(panelCountController.text.trim()) ?? 0,
          }
        }
      ];
    } else {
      assets['panels'] = [];
    }

    if (showAssetsSection && invertersEnabled && isInvertersFilled(catalog?['inverters'] as List?)) {
      assets['inverters'] = inverters.map((inv) {
        return {
          'type': 'INVERTER',
          'details': {
            'manufacturer': inv.manufacturerController.text.trim(),
            'model': inv.modelController.text.trim(),
            'size': inv.sizeController.text.trim(),
            'serial': inv.serialController.text.trim(),
          }
        };
      }).toList();
    } else {
      assets['inverters'] = [];
    }

    if (showAssetsSection && storagesEnabled && isStoragesFilled(catalog?['storages'] as List?)) {
      assets['storages'] = storages.map((stor) {
        return {
          'type': 'STORAGE',
          'details': {
            'manufacturer': stor.manufacturerController.text.trim(),
            'model': stor.modelController.text.trim(),
            'size': stor.sizeController.text.trim(),
            'serial': stor.serialController.text.trim(),
          }
        };
      }).toList();
    } else {
      assets['storages'] = [];
    }

    return assets;
  }
}

class AddAssetsView extends ConsumerStatefulWidget {
  final Map<String, dynamic> customerPayload;
  final Map<String, dynamic> sitePayload;
  final List<SystemDetails>? initialSystems;
  final String? openSystemName;

  const AddAssetsView({
    super.key,
    required this.customerPayload,
    required this.sitePayload,
    this.initialSystems,
    this.openSystemName,
  });

  @override
  ConsumerState<AddAssetsView> createState() => _AddAssetsViewState();
}

class _AddAssetsViewState extends ConsumerState<AddAssetsView> {
  final List<SystemFormState> _systems = [];
  bool _isFormValid = false;
  Map<String, dynamic>? _equipmentCatalog;
  bool _isLoadingCatalog = false;
  bool _isSavingAndExiting = false;
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSystems != null && widget.initialSystems!.isNotEmpty) {
      for (final sys in widget.initialSystems!) {
        final shouldExpand = widget.openSystemName != null
            ? sys.name.toLowerCase() == widget.openSystemName!.toLowerCase()
            : widget.initialSystems!.first == sys;
        _addExistingSystem(sys, isExpanded: shouldExpand);
      }
    } else {
      // Pre-populate with first system
      _addNewSystem();
    }
    _loadEquipmentCatalog();
  }

  Future<void> _loadEquipmentCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
    });
    try {
      final repo = ref.read(registrationRepositoryProvider);
      final data = await repo.getManufacturerDetails();
      setState(() {
        _equipmentCatalog = data;
        _isLoadingCatalog = false;
      });
      _updateFormState();
    } catch (e) {
      setState(() {
        _isLoadingCatalog = false;
      });
    }
  }

  @override
  void dispose() {
    for (final sys in _systems) {
      sys.dispose();
    }
    super.dispose();
  }

  void _addNewSystem() {
    final systemNumber = _systems.length + 1;
    final newSystem = SystemFormState(
      name: 'System $systemNumber',
    );

    // Expand the new system and collapse all others
    for (final sys in _systems) {
      sys.isExpanded = false;
    }

    // Set up listeners for the new system
    newSystem.sizeController.addListener(_onFieldChanged);
    newSystem.ownerController.addListener(_onFieldChanged);
    newSystem.installedByController.addListener(_onFieldChanged);
    newSystem.panelManufacturerController.addListener(_onFieldChanged);
    newSystem.panelSeriesController.addListener(_onFieldChanged);
    newSystem.panelWattageController.addListener(_onFieldChanged);
    newSystem.panelCountController.addListener(_onFieldChanged);
    newSystem.panelWattageController.addListener(() {
      if (newSystem.panelWattageController.text.isNotEmpty) {
        newSystem.panelWattageTouched = true;
      }
    });
    newSystem.inverterCountController.addListener(() {
      _updateInverterCount(newSystem, newSystem.inverterCountController.text);
    });
    newSystem.storageCountController.addListener(() {
      _updateStorageCount(newSystem, newSystem.storageCountController.text);
    });

    setState(() {
      _systems.add(newSystem);
    });
    _updateFormState();
  }

  void _addExistingSystem(SystemDetails systemDetails, {required bool isExpanded}) {
    final newSystem = SystemFormState(
      name: systemDetails.name,
      status: systemDetails.status.toUpperCase(),
      installationDate: systemDetails.installationDate != null ? DateTime.tryParse(systemDetails.installationDate!) : null,
      activationDate: systemDetails.activationDate != null ? DateTime.tryParse(systemDetails.activationDate!) : null,
      monitoringStartDate: systemDetails.monitoringStartDate != null ? DateTime.tryParse(systemDetails.monitoringStartDate!) : null,
      isExpanded: isExpanded,
      uuid: systemDetails.uuid,
      organizationUuid: systemDetails.organizationUuid,
    );

    newSystem.sizeController.text = systemDetails.size ?? '';
    newSystem.ownerController.text = systemDetails.assetOwner ?? '';
    newSystem.installedByController.text = systemDetails.installedBy;

    // Set touched flags to true since they are prefilled
    newSystem.sizeTouched = true;
    newSystem.ownerTouched = true;
    newSystem.installedByTouched = true;
    newSystem.installationDateTouched = true;
    newSystem.activationDateTouched = true;
    newSystem.monitoringStartDateTouched = true;

    // Parse assets
    final assets = systemDetails.assets;
    if (assets != null) {
      final panels = assets['panels'] as List?;
      final inverters = assets['inverters'] as List?;
      final storages = assets['storages'] as List?;

      final hasPanels = panels != null && panels.isNotEmpty;
      final hasInverters = inverters != null && inverters.isNotEmpty;
      final hasStorages = storages != null && storages.isNotEmpty;

      if (hasPanels || hasInverters || hasStorages) {
        newSystem.showAssetsSection = true;
      }

      if (hasPanels) {
        newSystem.panelsEnabled = true;
        final panel = panels[0];
        final details = panel['details'] as Map?;
        if (details != null) {
          newSystem.panelManufacturerController.text = details['manufacturer']?.toString() ?? '';
          newSystem.panelSeriesController.text = details['series']?.toString() ?? '';
          newSystem.panelWattageController.text = details['wattage']?.toString() ?? '';
          newSystem.panelCountController.text = details['noOfPanels']?.toString() ?? '';

          newSystem.panelManufacturerTouched = true;
          newSystem.panelSeriesTouched = true;
          newSystem.panelWattageTouched = true;
          newSystem.panelCountTouched = true;
        }
      }

      if (hasInverters) {
        newSystem.invertersEnabled = true;
        newSystem.inverterCountController.text = inverters.length.toString();
        for (final inv in inverters) {
          final details = inv['details'] as Map?;
          final invState = InverterFormState();
          if (details != null) {
            invState.manufacturerController.text = details['manufacturer']?.toString() ?? '';
            invState.modelController.text = details['model']?.toString() ?? '';
            invState.sizeController.text = details['size']?.toString() ?? '';
            invState.serialController.text = details['serial']?.toString() ?? '';

            invState.manufacturerTouched = true;
            invState.modelTouched = true;
            invState.sizeTouched = true;
            invState.serialTouched = true;
          }
          invState.manufacturerController.addListener(_onFieldChanged);
          invState.modelController.addListener(_onFieldChanged);
          invState.sizeController.addListener(_onFieldChanged);
          invState.serialController.addListener(_onFieldChanged);
          newSystem.inverters.add(invState);
        }
      }

      if (hasStorages) {
        newSystem.storagesEnabled = true;
        newSystem.storageCountController.text = storages.length.toString();
        for (final stor in storages) {
          final details = stor['details'] as Map?;
          final storState = StorageFormState();
          if (details != null) {
            storState.manufacturerController.text = details['manufacturer']?.toString() ?? '';
            storState.modelController.text = details['model']?.toString() ?? '';
            storState.sizeController.text = details['size']?.toString() ?? '';
            storState.serialController.text = details['serial']?.toString() ?? '';

            storState.manufacturerTouched = true;
            storState.modelTouched = true;
            storState.sizeTouched = true;
            storState.serialTouched = true;
          }
          storState.manufacturerController.addListener(_onFieldChanged);
          storState.modelController.addListener(_onFieldChanged);
          storState.sizeController.addListener(_onFieldChanged);
          storState.serialController.addListener(_onFieldChanged);
          newSystem.storages.add(storState);
        }
      }
    }

    // Parse contracted energy details
    final contractedEnergy = systemDetails.contractedEnergy;
    if (contractedEnergy != null && contractedEnergy.isNotEmpty) {
      newSystem.numYears = contractedEnergy.length;
      for (final ce in contractedEnergy) {
        if (ce is Map) {
          final year = ce['year'] as int?;
          final targetAnnual = ce['targetAnnual'];
          if (year != null) {
            final ctrl = TextEditingController(text: targetAnnual?.toString() ?? '');
            newSystem.yearControllers[year] = ctrl;
          }
        }
      }
    }

    // Parse system documents
    final docs = systemDetails.documents;
    if (docs != null && docs.isNotEmpty) {
      for (final doc in docs) {
        if (doc is Map) {
          newSystem.documents.add(
            SystemDocumentFormState(
              uuid: doc['uuid'] as String?,
              name: doc['name']?.toString() ?? '',
              type: doc['type']?.toString() ?? '',
              fileName: doc['fileName']?.toString() ?? '',
              fileType: doc['fileType']?.toString() ?? 'PDF',
              base64Content: doc['base64Content']?.toString() ?? '',
              uploadedDate: doc['uploadedDate']?.toString(),
              signedUrl: doc['signedUrl']?.toString(),
            ),
          );
        }
      }
    }

    // Set up listeners for the system fields
    newSystem.sizeController.addListener(_onFieldChanged);
    newSystem.ownerController.addListener(_onFieldChanged);
    newSystem.installedByController.addListener(_onFieldChanged);
    newSystem.panelManufacturerController.addListener(_onFieldChanged);
    newSystem.panelSeriesController.addListener(_onFieldChanged);
    newSystem.panelWattageController.addListener(_onFieldChanged);
    newSystem.panelCountController.addListener(_onFieldChanged);
    newSystem.panelWattageController.addListener(() {
      if (newSystem.panelWattageController.text.isNotEmpty) {
        newSystem.panelWattageTouched = true;
      }
    });
    newSystem.inverterCountController.addListener(() {
      _updateInverterCount(newSystem, newSystem.inverterCountController.text);
    });
    newSystem.storageCountController.addListener(() {
      _updateStorageCount(newSystem, newSystem.storageCountController.text);
    });

    setState(() {
      _systems.add(newSystem);
    });
    _updateFormState();
  }

  void _onFieldChanged() {
    final panelsCatalog = _equipmentCatalog?['panels'] as List?;
    for (final sys in _systems) {
      if (!sys.isPanelDetailsFilled(panelsCatalog) && sys.invertersEnabled) {
        sys.invertersEnabled = false;
      }
    }
    setState(() {});
    _updateFormState();
  }

  void _updateInverterCount(SystemFormState sys, String val) {
    setState(() {
      if (val.trim().isEmpty) {
        for (final inv in sys.inverters) {
          inv.dispose();
        }
        sys.inverters.clear();
        return;
      }
      int? count = int.tryParse(val.trim());
      if (count == null || count < 0) return;
      if (count > 10) count = 10;

      if (count > sys.inverters.length) {
        final diff = count - sys.inverters.length;
        for (int i = 0; i < diff; i++) {
          final inv = InverterFormState();
          inv.manufacturerController.addListener(_onFieldChanged);
          inv.modelController.addListener(_onFieldChanged);
          inv.sizeController.addListener(_onFieldChanged);
          inv.serialController.addListener(_onFieldChanged);
          sys.inverters.add(inv);
        }
      } else if (count < sys.inverters.length) {
        final diff = sys.inverters.length - count;
        for (int i = 0; i < diff; i++) {
          final removed = sys.inverters.removeLast();
          removed.dispose();
        }
      }
    });
    _updateFormState();
  }

  void _updateStorageCount(SystemFormState sys, String val) {
    setState(() {
      if (val.trim().isEmpty) {
        for (final stor in sys.storages) {
          stor.dispose();
        }
        sys.storages.clear();
        return;
      }
      int? count = int.tryParse(val.trim());
      if (count == null || count < 0) return;
      if (count > 10) count = 10;

      if (count > sys.storages.length) {
        final diff = count - sys.storages.length;
        for (int i = 0; i < diff; i++) {
          final stor = StorageFormState();
          stor.manufacturerController.addListener(_onFieldChanged);
          stor.modelController.addListener(_onFieldChanged);
          stor.sizeController.addListener(_onFieldChanged);
          stor.serialController.addListener(_onFieldChanged);
          sys.storages.add(stor);
        }
      } else if (count < sys.storages.length) {
        final diff = sys.storages.length - count;
        for (int i = 0; i < diff; i++) {
          final removed = sys.storages.removeLast();
          removed.dispose();
        }
      }
    });
    _updateFormState();
  }

  void _updateFormState() {
    bool allValid = true;
    for (final sys in _systems) {
      if (!sys.checkIsValid(_equipmentCatalog)) {
        allValid = false;
        break;
      }
    }
    if (allValid != _isFormValid) {
      setState(() {
        _isFormValid = allValid;
      });
    }
  }

  DateTime? _toUtcStartOfDay(DateTime? date) {
    if (date == null) return null;
    return DateTime.utc(date.year, date.month, date.day, 0, 0, 0, 0);
  }

  Future<void> _handleSave({bool exitAfterSave = true}) async {
    // Force touched validation on all fields
    setState(() {
      for (final sys in _systems) {
        sys.sizeTouched = true;
        sys.ownerTouched = true;
        sys.installedByTouched = true;
        sys.installationDateTouched = true;
        sys.activationDateTouched = true;
        sys.monitoringStartDateTouched = true;
        if (sys.showAssetsSection) {
          if (sys.panelsEnabled) {
            sys.panelManufacturerTouched = true;
            sys.panelSeriesTouched = true;
            sys.panelWattageTouched = true;
            sys.panelCountTouched = true;
          }
          if (sys.invertersEnabled) {
            for (final inv in sys.inverters) {
              inv.manufacturerTouched = true;
              inv.modelTouched = true;
              inv.sizeTouched = true;
              inv.serialTouched = true;
            }
          }
          if (sys.storagesEnabled) {
            for (final stor in sys.storages) {
              stor.manufacturerTouched = true;
              stor.modelTouched = true;
              stor.sizeTouched = true;
              stor.serialTouched = true;
            }
          }
        }
      }
    });

    _updateFormState();
    if (!_isFormValid) return;

    setState(() {
      if (exitAfterSave) {
        _isSavingAndExiting = true;
      } else {
        _isSavingProgress = true;
      }
    });

    try {
      final systemsPayload = _systems.map((sys) {
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

        final documentsData = sys.documents.map((doc) {
          final map = <String, dynamic>{
            'name': doc.name,
            'type': doc.type,
            'fileName': doc.fileName,
            'fileType': doc.fileType,
            'base64Content': doc.base64Content,
          };
          if (doc.uuid != null) map['uuid'] = doc.uuid;
          if (doc.uploadedDate != null) map['uploadedDate'] = doc.uploadedDate;
          if (doc.signedUrl != null) map['signedUrl'] = doc.signedUrl;
          return map;
        }).toList();

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
          'assets': sys.buildAssetsMap(_equipmentCatalog),
          'contractedEnergy': contractedEnergyData,
          'documents': documentsData,
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
          Navigator.of(context).pop(); // Back to manual registration
          Navigator.of(context).pop(); // Back to list view
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Systems',
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
              // System Accordion List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _systems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final sys = _systems[index];
                  return _buildSystemAccordion(sys, index);
                },
              ),
              const SizedBox(height: 24),

              // Add Additional System Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () {
                          _addNewSystem();
                        },
                  icon: const Icon(LucideIcons.plusCircle, size: 20),
                  label: const Text('Add Additional System'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00C49C),
                    side: const BorderSide(color: Color(0xFF00C49C)),
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
              const SizedBox(height: 32),

              // Action Buttons (Cancel / Save)
              _buildActionButtons(state),
              const SizedBox(height: 16),

              // Contracted Energy Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFormValid && !state.isSaving
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContractedEnergyView(
                                systems: _systems,
                                customerPayload: widget.customerPayload,
                                sitePayload: widget.sitePayload,
                                equipmentCatalog: _equipmentCatalog,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(LucideIcons.zap, size: 20),
                  label: const Text('Contracted Energy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: AppTheme.primaryColor,
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
              const SizedBox(height: 16),

              // Asset Document Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFormValid && !state.isSaving
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationDocumentsView(
                                systems: _systems,
                              ),
                            ),
                          );
                        }
                      : null,
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemAccordion(SystemFormState sys, int index) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              sys.isExpanded = !sys.isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: sys.isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
              border: Border.all(color: AppTheme.secondaryColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      sys.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  sys.isExpanded
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
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: AppTheme.secondaryColor),
                right: BorderSide(color: AppTheme.secondaryColor),
                bottom: BorderSide(color: AppTheme.secondaryColor),
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(
                  label: 'Assets Owner',
                  controller: sys.ownerController,
                  hintText: 'Enter asset owner',
                  errorText: sys.ownerTouched && sys.ownerController.text.trim().isEmpty
                      ? 'Assets owner is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Installed By',
                  controller: sys.installedByController,
                  hintText: 'Enter installer name',
                  errorText: sys.installedByTouched && sys.installedByController.text.trim().isEmpty
                      ? 'Installed by is required'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Solar System Size (DC)',
                        controller: sys.sizeController,
                        hintText: 'Enter system size',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        errorText: sys.sizeTouched && sys.sizeController.text.trim().isEmpty
                            ? 'Solar system size is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Status',
                        value: sys.status,
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            sys.status = val ?? 'ACTIVE';
                          });
                          _updateFormState();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Installation Date',
                  selectedDate: sys.installationDate,
                  errorText: sys.installationDateTouched && sys.installationDate == null
                      ? 'Installation date is required'
                      : null,
                  onTap: () async {
                    sys.installationDateTouched = true;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: sys.installationDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        sys.installationDate = picked;
                      });
                      _updateFormState();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Activation Date',
                  selectedDate: sys.activationDate,
                  errorText: sys.activationDateTouched && sys.activationDate == null
                      ? 'Activation date is required'
                      : null,
                  onTap: () async {
                    sys.activationDateTouched = true;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: sys.activationDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        sys.activationDate = picked;
                      });
                      _updateFormState();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Monitoring Start Date',
                  selectedDate: sys.monitoringStartDate,
                  errorText: sys.monitoringStartDateTouched && sys.monitoringStartDate == null
                      ? 'Monitoring start date is required'
                      : null,
                  onTap: () async {
                    sys.monitoringStartDateTouched = true;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: sys.monitoringStartDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        sys.monitoringStartDate = picked;
                      });
                      _updateFormState();
                    }
                  },
                ),

                const SizedBox(height: 24),
                // Toggle Assets details section
                if (!sys.showAssetsSection)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        sys.showAssetsSection = true;
                        sys.panelsEnabled = true;
                      });
                      _updateFormState();
                    },
                    icon: const Icon(LucideIcons.plusCircle, size: 18),
                    label: const Text('Add Assets Details (Panels, etc.)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: Color(0xFFDAE3E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else ...[
                  const Divider(color: Color(0xFFDAE3E1), height: 32),
                  _buildAssetsSection(sys),
                ],
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: sys.isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  String? _getPanelWattageError(SystemFormState sys) {
    final text = sys.panelWattageController.text.trim();
    if (sys.panelWattageTouched && text.isEmpty) {
      return 'Wattage is required';
    }
    if (text.isNotEmpty) {
      final range = getWattageRange(
        _equipmentCatalog?['panels'] as List?,
        sys.panelManufacturerController.text,
        sys.panelSeriesController.text,
      );
      if (range['min'] != null && range['max'] != null) {
        final val = double.tryParse(text);
        if (val == null || val < range['min']! || val > range['max']!) {
          return 'Wattage must be within ${range['min']!.toInt()}-${range['max']!.toInt()}kWh';
        }
      }
    }
    return null;
  }

  Widget _buildPanelWattageField(SystemFormState sys) {
    final range = getWattageRange(
      _equipmentCatalog?['panels'] as List?,
      sys.panelManufacturerController.text,
      sys.panelSeriesController.text,
    );
    final hasRange = range['min'] != null && range['max'] != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Panel Wattage',
          controller: sys.panelWattageController,
          hintText: 'Enter wattage (e.g. 400)',
          keyboardType: TextInputType.number,
          errorText: _getPanelWattageError(sys),
        ),
        if (hasRange && _getPanelWattageError(sys) == null) ...[
          const SizedBox(height: 4),
          Text(
            'Enter ${range['min']!.toInt()}-${range['max']!.toInt()}kWh',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF889492),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInverterSizeField(InverterFormState inv, int index) {
    final catalog = _equipmentCatalog?['inverters'] as List?;
    final rule = getSizeValidation(
      catalog,
      inv.manufacturerController.text,
      inv.modelController.text,
    );

    final errorText = inv.sizeTouched && inv.sizeController.text.trim().isEmpty
        ? 'Size is required'
        : (inv.sizeController.text.isNotEmpty
            ? validateSize(inv.sizeController.text, rule, 'Size')
            : null);

    if (rule.type == 'array') {
      return _buildDropdownField(
        label: 'Inverter Size (kW)',
        value: inv.sizeController.text,
        hintText: _isLoadingCatalog ? 'Loading sizes...' : 'Select size',
        disabled: _isLoadingCatalog || inv.modelController.text.isEmpty,
        errorText: errorText,
        items: rule.values.map((v) {
          return DropdownMenuItem(value: v, child: Text(v));
        }).toList(),
        onChanged: (val) {
          setState(() {
            inv.sizeController.text = val ?? '';
            inv.sizeTouched = true;
          });
          _updateFormState();
        },
      );
    }

    final hasRange = rule.type == 'range' && rule.min != null && rule.max != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Inverter Size (kW)',
          controller: inv.sizeController,
          hintText: 'Enter size',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: errorText,
        ),
        if (hasRange && errorText == null) ...[
          const SizedBox(height: 4),
          Text(
            'Enter ${rule.min!.toStringAsFixed(0)}-${rule.max!.toStringAsFixed(0)} kW',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF889492),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStorageSizeField(StorageFormState stor, int index) {
    final catalog = _equipmentCatalog?['storages'] as List?;
    final rule = getSizeValidation(
      catalog,
      stor.manufacturerController.text,
      stor.modelController.text,
    );

    final errorText = stor.sizeTouched && stor.sizeController.text.trim().isEmpty
        ? 'Size is required'
        : (stor.sizeController.text.isNotEmpty
            ? validateSize(stor.sizeController.text, rule, 'Size')
            : null);

    if (rule.type == 'array') {
      return _buildDropdownField(
        label: 'Battery Size (kWh)',
        value: stor.sizeController.text,
        hintText: _isLoadingCatalog ? 'Loading sizes...' : 'Select size',
        disabled: _isLoadingCatalog || stor.modelController.text.isEmpty,
        errorText: errorText,
        items: rule.values.map((v) {
          return DropdownMenuItem(value: v, child: Text(v));
        }).toList(),
        onChanged: (val) {
          setState(() {
            stor.sizeController.text = val ?? '';
            stor.sizeTouched = true;
          });
          _updateFormState();
        },
      );
    }

    final hasRange = rule.type == 'range' && rule.min != null && rule.max != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Battery Size (kWh)',
          controller: stor.sizeController,
          hintText: 'Enter size',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: errorText,
        ),
        if (hasRange && errorText == null) ...[
          const SizedBox(height: 4),
          Text(
            'Enter ${rule.min!.toStringAsFixed(0)}-${rule.max!.toStringAsFixed(0)} kWh',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF889492),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssetsSection(SystemFormState sys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assets Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),

        // Panels Details Expansion
        CheckboxListTile(
          title: Text(
            'Panel Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          value: sys.panelsEnabled,
          onChanged: (val) {
            setState(() {
              sys.panelsEnabled = val ?? false;
              if (!sys.panelsEnabled) {
                sys.invertersEnabled = false;
              }
            });
            _updateFormState();
          },
          activeColor: const Color(0xFF00C49C),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (sys.panelsEnabled) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4, bottom: 12),
            child: Column(
              children: [
                _buildInputField(
                  label: '# of Panels',
                  controller: sys.panelCountController,
                  hintText: 'Enter # of panels',
                  keyboardType: TextInputType.number,
                  errorText: sys.panelCountTouched && (int.tryParse(sys.panelCountController.text.trim()) ?? 0) <= 0
                      ? 'Must be 1 or more'
                      : null,
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Panel Manufacturer',
                  value: sys.panelManufacturerController.text,
                  hintText: _isLoadingCatalog ? 'Loading manufacturers...' : 'Select manufacturer',
                  disabled: _isLoadingCatalog,
                  errorText: sys.panelManufacturerTouched && sys.panelManufacturerController.text.isEmpty
                      ? 'Manufacturer is required'
                      : null,
                  items: getManufacturers(_equipmentCatalog?['panels'] as List?).map((mfg) {
                    return DropdownMenuItem(value: mfg, child: Text(mfg));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      sys.panelManufacturerController.text = val ?? '';
                      sys.panelManufacturerTouched = true;
                      sys.panelSeriesController.text = ''; // Reset model
                      sys.panelSeriesTouched = false;
                      sys.panelWattageController.text = ''; // Reset wattage
                      sys.panelWattageTouched = false;
                    });
                    _updateFormState();
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Panel Series / Model',
                  value: sys.panelSeriesController.text,
                  hintText: _isLoadingCatalog ? 'Loading models...' : 'Select model',
                  disabled: _isLoadingCatalog || sys.panelManufacturerController.text.isEmpty,
                  errorText: sys.panelSeriesTouched && sys.panelSeriesController.text.isEmpty
                      ? 'Model is required'
                      : null,
                  items: getSeriesForManufacturer(
                    _equipmentCatalog?['panels'] as List?,
                    sys.panelManufacturerController.text,
                  ).map((model) {
                    return DropdownMenuItem(value: model, child: Text(model));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      sys.panelSeriesController.text = val ?? '';
                      sys.panelSeriesTouched = true;
                      sys.panelWattageController.text = ''; // Reset wattage
                      sys.panelWattageTouched = false;
                    });
                    _updateFormState();
                  },
                ),
                const SizedBox(height: 12),
                _buildPanelWattageField(sys),
              ],
            ),
          ),
        ],

        // Inverters Details Expansion
        CheckboxListTile(
          title: Text(
            'Inverter Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: sys.isPanelDetailsFilled(_equipmentCatalog?['panels'] as List?)
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          value: sys.invertersEnabled,
          onChanged: sys.isPanelDetailsFilled(_equipmentCatalog?['panels'] as List?)
              ? (val) {
                  setState(() {
                    sys.invertersEnabled = val ?? false;
                    if (sys.invertersEnabled && sys.inverters.isEmpty) {
                      sys.inverterCountController.text = '1';
                      _updateInverterCount(sys, '1');
                    }
                  });
                  _updateFormState();
                }
              : null,
          activeColor: const Color(0xFF00C49C),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (sys.invertersEnabled) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: _buildInputField(
                    label: '# of Inverters',
                    controller: sys.inverterCountController,
                    hintText: 'Enter #',
                    keyboardType: TextInputType.number,
                    errorText: sys.inverterCountController.text.trim().isEmpty
                        ? 'Count is required'
                        : (int.tryParse(sys.inverterCountController.text.trim()) ?? 0) <= 0
                            ? 'Must be 1 or more'
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(sys.inverters.length, (i) {
                  final inv = sys.inverters[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sys.inverters.length > 1) ...[
                        Text(
                          'Inverter ${i + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildDropdownField(
                        label: 'Inverter Manufacturer',
                        value: inv.manufacturerController.text,
                        hintText: _isLoadingCatalog ? 'Loading manufacturers...' : 'Select manufacturer',
                        disabled: _isLoadingCatalog,
                        errorText: sys.inverterCountController.text.isNotEmpty &&
                                inv.manufacturerTouched &&
                                inv.manufacturerController.text.isEmpty
                            ? 'Manufacturer is required'
                            : null,
                        items: getManufacturers(_equipmentCatalog?['inverters'] as List?).map((mfg) {
                          return DropdownMenuItem(value: mfg, child: Text(mfg));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            inv.manufacturerController.text = val ?? '';
                            inv.manufacturerTouched = true;
                            inv.modelController.text = ''; // Reset model
                            inv.modelTouched = false;
                            inv.sizeController.text = ''; // Reset size
                            inv.sizeTouched = false;
                          });
                          _updateFormState();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                        label: 'Inverter Model',
                        value: inv.modelController.text,
                        hintText: _isLoadingCatalog ? 'Loading models...' : 'Select model',
                        disabled: _isLoadingCatalog || inv.manufacturerController.text.isEmpty,
                        errorText: sys.inverterCountController.text.isNotEmpty &&
                                inv.modelTouched &&
                                inv.modelController.text.isEmpty
                            ? 'Model is required'
                            : null,
                        items: getSeriesForManufacturer(
                          _equipmentCatalog?['inverters'] as List?,
                          inv.manufacturerController.text,
                        ).map((model) {
                          return DropdownMenuItem(value: model, child: Text(model));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            inv.modelController.text = val ?? '';
                            inv.modelTouched = true;
                            inv.sizeController.text = ''; // Reset size
                            inv.sizeTouched = false;
                          });
                          _updateFormState();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildInverterSizeField(inv, i),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Serial Number',
                        controller: inv.serialController,
                        hintText: 'Enter serial number',
                        errorText: sys.inverterCountController.text.isNotEmpty &&
                                inv.serialTouched &&
                                inv.serialController.text.trim().isEmpty
                            ? 'Serial number is required'
                            : null,
                      ),
                      if (i < sys.inverters.length - 1)
                        const Divider(color: Color(0xFFDAE3E1), height: 32),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],

        // Storage Details Expansion
        CheckboxListTile(
          title: Text(
            'Battery Storage Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          value: sys.storagesEnabled,
          onChanged: (val) {
            setState(() {
              sys.storagesEnabled = val ?? false;
              if (sys.storagesEnabled && sys.storages.isEmpty) {
                sys.storageCountController.text = '1';
                _updateStorageCount(sys, '1');
              }
            });
            _updateFormState();
          },
          activeColor: const Color(0xFF00C49C),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (sys.storagesEnabled) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: _buildInputField(
                    label: '# of Storage',
                    controller: sys.storageCountController,
                    hintText: 'Enter #',
                    keyboardType: TextInputType.number,
                    errorText: sys.storageCountController.text.trim().isEmpty
                        ? 'Count is required'
                        : (int.tryParse(sys.storageCountController.text.trim()) ?? 0) <= 0
                            ? 'Must be 1 or more'
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(sys.storages.length, (i) {
                  final stor = sys.storages[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sys.storages.length > 1) ...[
                        Text(
                          'Battery Storage ${i + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildDropdownField(
                        label: 'Battery Manufacturer',
                        value: stor.manufacturerController.text,
                        hintText: _isLoadingCatalog ? 'Loading manufacturers...' : 'Select manufacturer',
                        disabled: _isLoadingCatalog,
                        errorText: sys.storageCountController.text.isNotEmpty &&
                                stor.manufacturerTouched &&
                                stor.manufacturerController.text.isEmpty
                            ? 'Manufacturer is required'
                            : null,
                        items: getManufacturers(_equipmentCatalog?['storages'] as List?).map((mfg) {
                          return DropdownMenuItem(value: mfg, child: Text(mfg));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            stor.manufacturerController.text = val ?? '';
                            stor.manufacturerTouched = true;
                            stor.modelController.text = ''; // Reset model
                            stor.modelTouched = false;
                            stor.sizeController.text = ''; // Reset size
                            stor.sizeTouched = false;
                          });
                          _updateFormState();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                        label: 'Battery Model',
                        value: stor.modelController.text,
                        hintText: _isLoadingCatalog ? 'Loading models...' : 'Select model',
                        disabled: _isLoadingCatalog || stor.manufacturerController.text.isEmpty,
                        errorText: sys.storageCountController.text.isNotEmpty &&
                                stor.modelTouched &&
                                stor.modelController.text.isEmpty
                            ? 'Model is required'
                            : null,
                        items: getSeriesForManufacturer(
                          _equipmentCatalog?['storages'] as List?,
                          stor.manufacturerController.text,
                        ).map((model) {
                          return DropdownMenuItem(value: model, child: Text(model));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            stor.modelController.text = val ?? '';
                            stor.modelTouched = true;
                            stor.sizeController.text = ''; // Reset size
                            stor.sizeTouched = false;
                          });
                          _updateFormState();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildStorageSizeField(stor, i),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Serial Number',
                        controller: stor.serialController,
                        hintText: 'Enter serial number',
                        errorText: sys.storageCountController.text.isNotEmpty &&
                                stor.serialTouched &&
                                stor.serialController.text.trim().isEmpty
                            ? 'Serial number is required'
                            : null,
                      ),
                      if (i < sys.storages.length - 1)
                        const Divider(color: Color(0xFFDAE3E1), height: 32),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
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
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.inputBgColor,
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? hintText,
    bool disabled = false,
    String? errorText,
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
          hint: hintText != null ? Text(hintText) : null,
          items: disabled ? null : items,
          onChanged: disabled ? null : onChanged,
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

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required String? errorText,
    required VoidCallback onTap,
  }) {
    final displayValue = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate)
        : '';
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
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextField(
              controller: TextEditingController(text: displayValue),
              readOnly: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.inputBgColor,
                hintText: 'Select date',
                suffixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
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
