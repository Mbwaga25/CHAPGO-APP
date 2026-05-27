class AuditEntry {
  final DateTime occurredAt;
  final String actorType;
  final String? actorPhone;
  final String action;
  final String? resourceType;
  final String? ipAddress;

  AuditEntry({
    required this.occurredAt,
    required this.actorType,
    this.actorPhone,
    required this.action,
    this.resourceType,
    this.ipAddress,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      actorType: json['actor_type'] as String? ?? 'anonymous',
      actorPhone: json['actor_phone'] as String?,
      action: json['action'] as String? ?? '',
      resourceType: json['resource_type'] as String?,
      ipAddress: json['ip_address'] as String?,
    );
  }
}
