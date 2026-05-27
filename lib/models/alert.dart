class TheftAlert {
  final int id;
  final String vehiclePlate;
  final String? stationName;
  final DateTime detectedAt;
  final DateTime? ownerNotifiedAt;

  TheftAlert({
    required this.id,
    required this.vehiclePlate,
    this.stationName,
    required this.detectedAt,
    this.ownerNotifiedAt,
  });

  bool get isNotified => ownerNotifiedAt != null;

  factory TheftAlert.fromJson(Map<String, dynamic> json) {
    return TheftAlert(
      id: json['id'] as int,
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      stationName: json['station_name'] as String?,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      ownerNotifiedAt: json['owner_notified_at'] != null
          ? DateTime.parse(json['owner_notified_at'] as String)
          : null,
    );
  }
}

class WatchlistItem {
  final String vehiclePlate;
  final String? referenceNumber;
  final DateTime flaggedAt;
  final String? lastKnownLocation;
  final String? reporterPhone;

  WatchlistItem({
    required this.vehiclePlate,
    this.referenceNumber,
    required this.flaggedAt,
    this.lastKnownLocation,
    this.reporterPhone,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      referenceNumber: json['reference_number'] as String?,
      flaggedAt: DateTime.parse(json['flagged_at'] as String),
      lastKnownLocation: json['last_known_location'] as String?,
      reporterPhone: json['reporter_phone'] as String?,
    );
  }
}
