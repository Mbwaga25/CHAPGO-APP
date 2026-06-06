double _parseNum(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

class DashboardMetrics {
  final int drivers;
  final int stations;
  final int saccos;
  final int scansLast30Days;
  final int activeLoans;
  final int activeWatchlist;
  final int openEscalations;
  
  // Sacco specific fields
  final int activeMembers;
  final double collections30d;
  final int activeLoansCount;
  final double activeLoansValue;
  final bool isSacco;

  DashboardMetrics({
    this.drivers = 0,
    this.stations = 0,
    this.saccos = 0,
    this.scansLast30Days = 0,
    this.activeLoans = 0,
    this.activeWatchlist = 0,
    this.openEscalations = 0,
    this.activeMembers = 0,
    this.collections30d = 0.0,
    this.activeLoansCount = 0,
    this.activeLoansValue = 0.0,
    this.isSacco = false,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('active_members')) {
      return DashboardMetrics(
        activeMembers: json['active_members'] as int? ?? 0,
        collections30d: _parseNum(json['collections_30d_tsh']),
        activeLoansCount: json['active_loans_count'] as int? ?? 0,
        activeLoansValue: _parseNum(json['active_loans_value_tsh']),
        isSacco: true,
      );
    }
    return DashboardMetrics(
      drivers: json['drivers'] as int? ?? 0,
      stations: json['stations'] as int? ?? 0,
      saccos: json['saccos'] as int? ?? 0,
      scansLast30Days: json['scans_last_30_days'] as int? ?? 0,
      activeLoans: json['active_loans'] as int? ?? 0,
      activeWatchlist: json['active_watchlist'] as int? ?? 0,
      openEscalations: json['open_escalations'] as int? ?? 0,
      isSacco: false,
    );
  }
}
