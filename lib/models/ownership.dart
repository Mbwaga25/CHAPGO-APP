class OwnershipData {
  final int members;
  final int totalUnits;

  OwnershipData({this.members = 0, this.totalUnits = 0});

  factory OwnershipData.fromJson(Map<String, dynamic> json) {
    return OwnershipData(
      members: json['members'] as int? ?? 0,
      totalUnits: json['total_units'] as int? ?? 0,
    );
  }
}
