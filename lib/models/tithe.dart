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
      transferredTsh: (json['transferred_tsh'] as num?)?.toDouble() ?? 0,
      pendingTsh: (json['pending_tsh'] as num?)?.toDouble() ?? 0,
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
      subsidiaryProfitTsh: (json['subsidiary_profit_tsh'] as num?)?.toDouble() ?? 0,
      titheAmountTsh: (json['tithe_amount_tsh'] as num?)?.toDouble() ?? 0,
      transferStatus: json['transfer_status'] as String? ?? 'pending',
      destination: json['destination'] as String? ?? '',
    );
  }
}
