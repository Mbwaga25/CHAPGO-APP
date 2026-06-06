double _parseNum(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

class TitheTotals {
  final double transferredTsh;
  final double pendingTsh;
  final int totalTransactions;

  TitheTotals({
    this.transferredTsh = 0,
    this.pendingTsh = 0,
    this.totalTransactions = 0,
  });

  factory TitheTotals.fromJson(Map<String, dynamic> json) {
    return TitheTotals(
      transferredTsh: _parseNum(json['transferred_tsh']),
      pendingTsh: _parseNum(json['pending_tsh']),
      totalTransactions: json['total_transactions'] as int? ?? 0,
    );
  }
}

class TitheTransaction {
  final String subsidiary;
  final String periodStart;
  final String periodEnd;
  final double subsidiaryProfitTsh;
  final double titheAmountTsh;
  final String transferStatus;
  final String destination;

  TitheTransaction({
    required this.subsidiary,
    required this.periodStart,
    required this.periodEnd,
    required this.subsidiaryProfitTsh,
    required this.titheAmountTsh,
    required this.transferStatus,
    required this.destination,
  });

  factory TitheTransaction.fromJson(Map<String, dynamic> json) {
    return TitheTransaction(
      subsidiary: json['subsidiary'] as String? ?? '',
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      subsidiaryProfitTsh: _parseNum(json['subsidiary_profit_tsh']),
      titheAmountTsh: _parseNum(json['tithe_amount_tsh']),
      transferStatus: json['transfer_status'] as String? ?? 'pending',
      destination: json['destination'] as String? ?? '',
    );
  }
}
