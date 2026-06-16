import '../models/portfolio_entities.dart';

class PortfolioMetricsModel extends PortfolioMetricsEntity {
  PortfolioMetricsModel({
    required super.yesterday,
    required super.last30Days,
    required super.allTime,
    required super.carsOffRoad,
    required super.treeSeedlings,
    required super.homesPowered,
  });

  factory PortfolioMetricsModel.fromJson(Map<String, dynamic> json) {
    return PortfolioMetricsModel(
      yesterday: (json['yesterday'] ?? 0).toDouble(),
      last30Days: (json['last30Days'] ?? 0).toDouble(),
      allTime: (json['allTime'] ?? 0).toDouble(),
      carsOffRoad: (json['carsOffRoad'] ?? 0).toDouble(),
      treeSeedlings: (json['treeSeedlings'] ?? 0).toDouble(),
      homesPowered: (json['homesPowered'] ?? 0).toDouble(),
    );
  }
}

class EnergyDataPointModel extends EnergyDataPointEntity {
  EnergyDataPointModel({
    required super.date,
    required super.totalProductionWh,
    super.contractedEnergy,
    required super.averageProductionWh,
  });

  factory EnergyDataPointModel.fromJson(Map<String, dynamic> json) {
    return EnergyDataPointModel(
      date: json['date'] ?? '',
      totalProductionWh: (json['totalProductionWh'] ?? 0).toDouble(),
      contractedEnergy: json['contractedEnergy']?.toDouble(),
      averageProductionWh: (json['averageProductionWh'] ?? 0).toDouble(),
    );
  }
}

class PortfolioFilterOptionsModel extends PortfolioFilterOptionsEntity {
  PortfolioFilterOptionsModel({
    required super.markets,
    required super.installedBy,
    required super.inverterManufacturers,
  });

  factory PortfolioFilterOptionsModel.fromJson(Map<String, dynamic> json) {
    final options = json['filterOptions'] ?? {};
    return PortfolioFilterOptionsModel(
      markets: List<String>.from(options['markets'] ?? []),
      installedBy: List<String>.from(options['installedBy'] ?? []),
      inverterManufacturers: List<String>.from(
        options['inverterManufacturers'] ?? [],
      ),
    );
  }
}

class SystemsDataPointModel extends SystemsDataPointEntity {
  SystemsDataPointModel({
    required super.date,
    required super.newSystems,
    super.average,
    super.cumulativeSystems,
  });

  factory SystemsDataPointModel.fromJson(Map<String, dynamic> json) {
    return SystemsDataPointModel(
      date: json['date'] ?? '',
      newSystems: (json['newSystems'] ?? 0).toDouble(),
      average: json['average']?.toDouble(),
      cumulativeSystems: json['cumulativeSystems']?.toDouble(),
    );
  }
}

class PerformanceRatioDataPointModel extends PerformanceRatioDataPointEntity {
  PerformanceRatioDataPointModel({
    required super.date,
    required super.performanceRatio,
    required super.actualWh,
    required super.systemsWithContract,
    required super.totalExpectedWh,
  });

  factory PerformanceRatioDataPointModel.fromJson(Map<String, dynamic> json) {
    return PerformanceRatioDataPointModel(
      date: json['date'] ?? '',
      performanceRatio: (json['performanceRatio'] ?? 0).toDouble(),
      actualWh: (json['actualWh'] ?? 0).toDouble(),
      systemsWithContract: (json['systemsWithContract'] ?? 0).toDouble(),
      totalExpectedWh: (json['totalExpectedWh'] ?? 0).toDouble(),
    );
  }
}

class ZeroProductionDataPointModel extends ZeroProductionDataPointEntity {
  ZeroProductionDataPointModel({
    required super.date,
    required super.zeroProductionSystems,
    super.totalSystems,
  });

  factory ZeroProductionDataPointModel.fromJson(Map<String, dynamic> json) {
    return ZeroProductionDataPointModel(
      date: json['date'] ?? '',
      zeroProductionSystems: (json['zeroProductionSystems'] ?? 0).toDouble(),
      totalSystems: json['totalSystems'] != null
          ? (json['totalSystems'] as num).toDouble()
          : null,
    );
  }
}

class NonCommsSystemModel extends NonCommsSystemEntity {
  NonCommsSystemModel({
    required super.siteAddress,
    required super.systemName,
    required super.installedBy,
    required super.manufacturer,
    super.startDate,
    super.endDate,
    super.alertDate,
  });

  factory NonCommsSystemModel.fromJson(Map<String, dynamic> json) {
    final siteDetails = json['siteDetails'] ?? {};
    final addressParts = [
      siteDetails['siteAddress'],
      siteDetails['city'],
      siteDetails['state'],
      siteDetails['zipCode'],
    ].where((part) => part != null && part.toString().isNotEmpty).toList();
    final addressString = addressParts.join(', ');

    return NonCommsSystemModel(
      siteAddress: addressString.isEmpty ? 'NA' : addressString,
      systemName: json['systemName'] ?? '',
      installedBy: json['installedBy'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      startDate: json['startDate'],
      endDate: json['endDate'],
      alertDate: json['alertDate'],
    );
  }
}

class NonCommsResponseModel extends NonCommsResponseEntity {
  NonCommsResponseModel({
    required List<NonCommsSystemModel> super.data,
    required super.total,
  });

  factory NonCommsResponseModel.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return NonCommsResponseModel(
      data: dataList.map((item) => NonCommsSystemModel.fromJson(item)).toList(),
      total: json['total'] ?? 0,
    );
  }
}
