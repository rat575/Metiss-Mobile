class CustomerDetails {
  final String uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  CustomerDetails({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      uuid: json['uuid'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    };
  }
}

class SiteDetails {
  final String uuid;
  final String siteAddress;
  final String city;
  final String state;
  final String zipCode;

  SiteDetails({
    required this.uuid,
    required this.siteAddress,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  factory SiteDetails.fromJson(Map<String, dynamic> json) {
    return SiteDetails(
      uuid: json['uuid'] ?? '',
      siteAddress: json['siteAddress'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'siteAddress': siteAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }

  String get formattedAddress {
    final parts = [
      siteAddress,
      city,
      state,
      zipCode,
    ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }
}

class SystemDetails {
  final String uuid;
  final String? organizationUuid;
  final String name;
  final String? size;
  final String? assetOwner;
  final String installedBy;
  final String status;
  final String? installationDate;
  final String? activationDate;
  final String? monitoringStartDate;
  final Map<String, dynamic>? assets;
  final List<dynamic>? contractedEnergy;
  final List<dynamic>? documents;

  SystemDetails({
    required this.uuid,
    this.organizationUuid,
    required this.name,
    this.size,
    this.assetOwner,
    required this.installedBy,
    required this.status,
    this.installationDate,
    this.activationDate,
    this.monitoringStartDate,
    this.assets,
    this.contractedEnergy,
    this.documents,
  });

  factory SystemDetails.fromJson(Map<String, dynamic> json) {
    return SystemDetails(
      uuid: json['uuid'] ?? '',
      organizationUuid: json['organizationUuid'],
      name: json['name'] ?? '',
      size: json['size']?.toString(),
      assetOwner: json['assetOwner'],
      installedBy: json['installedBy'] ?? '',
      status: json['status'] ?? 'INACTIVE',
      installationDate: json['installationDate'],
      activationDate: json['activationDate'],
      monitoringStartDate: json['monitoringStartDate'],
      assets: json['assets'] as Map<String, dynamic>?,
      contractedEnergy: json['contractedEnergy'] as List<dynamic>?,
      documents: json['documents'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'organizationUuid': organizationUuid,
      'name': name,
      'size': size,
      'assetOwner': assetOwner,
      'installedBy': installedBy,
      'status': status,
      'installationDate': installationDate,
      'activationDate': activationDate,
      'monitoringStartDate': monitoringStartDate,
      'assets': assets,
      'contractedEnergy': contractedEnergy,
      'documents': documents,
    };
  }

  String get assetTypeString {
    if (assets == null) return 'N/A';
    final parts = <String>[];
    if (assets!['panels'] != null && (assets!['panels'] as List).isNotEmpty) {
      parts.add('PANEL');
    }
    if (assets!['inverters'] != null &&
        (assets!['inverters'] as List).isNotEmpty) {
      parts.add('INVERTER');
    }
    if (assets!['storages'] != null &&
        (assets!['storages'] as List).isNotEmpty) {
      parts.add('STORAGE');
    }
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  int? get panelCount {
    final panels = assets?['panels'] as List?;
    if (panels == null || panels.isEmpty) return null;
    final details = panels[0]['details'] as Map?;
    final val = details?['noOfPanels'];
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString());
  }

  String? get panelManufacturer {
    final panels = assets?['panels'] as List?;
    if (panels == null || panels.isEmpty) return null;
    final details = panels[0]['details'] as Map?;
    return details?['manufacturer'] as String?;
  }

  String? get panelSeries {
    final panels = assets?['panels'] as List?;
    if (panels == null || panels.isEmpty) return null;
    final details = panels[0]['details'] as Map?;
    return details?['series'] as String?;
  }

  String? get panelWattage {
    final panels = assets?['panels'] as List?;
    if (panels == null || panels.isEmpty) return null;
    final details = panels[0]['details'] as Map?;
    return details?['wattage']?.toString();
  }

  List<dynamic> get inverters => assets?['inverters'] as List? ?? [];

  List<dynamic> get storages => assets?['storages'] as List? ?? [];
}

class RegistrationListEntry {
  final CustomerDetails customer;
  final SiteDetails site;
  final List<SystemDetails> system;

  RegistrationListEntry({
    required this.customer,
    required this.site,
    required this.system,
  });

  factory RegistrationListEntry.fromJson(Map<String, dynamic> json) {
    final systemsList = json['system'] as List? ?? [];
    return RegistrationListEntry(
      customer: CustomerDetails.fromJson(json['customer'] ?? {}),
      site: SiteDetails.fromJson(json['site'] ?? {}),
      system: systemsList.map((sys) => SystemDetails.fromJson(sys)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer': customer.toJson(),
      'site': site.toJson(),
      'system': system.map((sys) => sys.toJson()).toList(),
    };
  }
}

class RegistrationListResponse {
  final List<RegistrationListEntry> result;
  final int total;
  final int page;
  final int pageSize;

  RegistrationListResponse({
    required this.result,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory RegistrationListResponse.fromJson(Map<String, dynamic> json) {
    final resultList = json['result'] as List? ?? [];
    return RegistrationListResponse(
      result: resultList
          .map((entry) => RegistrationListEntry.fromJson(entry))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.map((entry) => entry.toJson()).toList(),
      'total': total,
      'page': page,
      'pageSize': pageSize,
    };
  }
}
