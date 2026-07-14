class QuarterlyReport {
  final String id;
  final int quarterNumber;
  final int reportYear;
  final String periodStart;
  final String periodEnd;
  final int totalMembers;
  final int totalScans;
  final DateTime? deliveredToRcAt;

  QuarterlyReport({
    required this.id,
    required this.quarterNumber,
    required this.reportYear,
    required this.periodStart,
    required this.periodEnd,
    this.totalMembers = 0,
    this.totalScans = 0,
    this.deliveredToRcAt,
  });

  bool get isDelivered => deliveredToRcAt != null;

  factory QuarterlyReport.fromJson(Map<String, dynamic> json) {
    return QuarterlyReport(
      id: json['id']?.toString() ?? '',
      quarterNumber: json['quarter_number'] as int,
      reportYear: json['report_year'] as int,
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      totalMembers: json['total_members'] as int? ?? 0,
      totalScans: json['total_scans'] as int? ?? 0,
      deliveredToRcAt: json['delivered_to_rc_at'] != null
          ? DateTime.parse(json['delivered_to_rc_at'] as String)
          : null,
    );
  }
}
