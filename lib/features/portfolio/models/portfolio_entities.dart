class PortfolioMetricsEntity {
  final double yesterday;
  final double last30Days;
  final double allTime;
  final double carsOffRoad;
  final double treeSeedlings;
  final double homesPowered;

  PortfolioMetricsEntity({
    required this.yesterday,
    required this.last30Days,
    required this.allTime,
    required this.carsOffRoad,
    required this.treeSeedlings,
    required this.homesPowered,
  });
}

class EnergyDataPointEntity {
  final String date;
  final double totalProductionWh;
  final double? contractedEnergy;
  final double averageProductionWh;

  EnergyDataPointEntity({
    required this.date,
    required this.totalProductionWh,
    this.contractedEnergy,
    required this.averageProductionWh,
  });
}

class PortfolioFilterOptionsEntity {
  final List<String> markets;
  final List<String> installedBy;
  final List<String> inverterManufacturers;

  PortfolioFilterOptionsEntity({
    required this.markets,
    required this.installedBy,
    required this.inverterManufacturers,
  });
}

class SystemsDataPointEntity {
  final String date;
  final double newSystems;
  final double? average;
  final double? cumulativeSystems;

  SystemsDataPointEntity({
    required this.date,
    required this.newSystems,
    this.average,
    this.cumulativeSystems,
  });
}

class PerformanceRatioDataPointEntity {
  final String date;
  final double performanceRatio;
  final double actualWh;
  final double systemsWithContract;
  final double totalExpectedWh;

  PerformanceRatioDataPointEntity({
    required this.date,
    required this.performanceRatio,
    required this.actualWh,
    required this.systemsWithContract,
    required this.totalExpectedWh,
  });
}

class ZeroProductionDataPointEntity {
  final String date;
  final double zeroProductionSystems;
  final double? totalSystems;

  ZeroProductionDataPointEntity({
    required this.date,
    required this.zeroProductionSystems,
    this.totalSystems,
  });
}

class NonCommsSystemEntity {
  final String siteAddress;
  final String systemName;
  final String installedBy;
  final String manufacturer;
  final String? startDate;
  final String? endDate;
  final String? alertDate;

  NonCommsSystemEntity({
    required this.siteAddress,
    required this.systemName,
    required this.installedBy,
    required this.manufacturer,
    this.startDate,
    this.endDate,
    this.alertDate,
  });
}

class NonCommsResponseEntity {
  final List<NonCommsSystemEntity> data;
  final int total;

  NonCommsResponseEntity({required this.data, required this.total});
}
