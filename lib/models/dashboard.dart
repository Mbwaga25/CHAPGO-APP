class DashboardMetrics {
  final int drivers;
  final int stations;
  final int saccos;
  final int scansLast30Days;
  final int activeLoans;
  final int activeWatchlist;
  final int openEscalations;

  DashboardMetrics({
    this.drivers = 0,
    this.stations = 0,
    this.saccos = 0,
    this.scansLast30Days = 0,
    this.activeLoans = 0,
    this.activeWatchlist = 0,
    this.openEscalations = 0,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      drivers: json['drivers'] as int? ?? 0,
      stations: json['stations'] as int? ?? 0,
      saccos: json['saccos'] as int? ?? 0,
      scansLast30Days: json['scans_last_30_days'] as int? ?? 0,
      activeLoans: json['active_loans'] as int? ?? 0,
      activeWatchlist: json['active_watchlist'] as int? ?? 0,
      openEscalations: json['open_escalations'] as int? ?? 0,
    );
  }
}
