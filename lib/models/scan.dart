class Scan {
  final int? id;
  final String driverName;
  final String? stationName;
  final double liters;
  final double amountTsh;
  final String paymentMethod;
  final String? vehiclePlate;
  final DateTime? scannedAt;
  final bool flagged;

  Scan({
    this.id,
    required this.driverName,
    this.stationName,
    required this.liters,
    required this.amountTsh,
    required this.paymentMethod,
    this.vehiclePlate,
    this.scannedAt,
    this.flagged = false,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      id: json['id'] as int?,
      driverName: json['driver_name'] as String? ?? '',
      stationName: json['station_name'] as String?,
      liters: double.tryParse((json['liters'] ?? '0').toString()) ?? 0,
      amountTsh: double.tryParse((json['amount_tsh'] ?? '0').toString()) ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      vehiclePlate: json['vehicle_plate'] as String?,
      scannedAt: json['scanned_at'] != null ? DateTime.parse(json['scanned_at']) : null,
      flagged: json['flagged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'qr_token': null,
    'liters': liters,
    'amount_tsh': amountTsh,
    'payment_method': paymentMethod,
  };
}

class DailySummary {
  final int scanCount;
  final double totalLiters;
  final double totalAmountTsh;

  DailySummary({
    this.scanCount = 0,
    this.totalLiters = 0,
    this.totalAmountTsh = 0,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      scanCount: int.tryParse((json['scan_count'] ?? '0').toString()) ?? 0,
      totalLiters: double.tryParse((json['total_liters'] ?? '0').toString()) ?? 0,
      totalAmountTsh: double.tryParse((json['total_amount_tsh'] ?? '0').toString()) ?? 0,
    );
  }
}
