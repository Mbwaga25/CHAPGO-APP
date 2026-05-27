enum UserRole { stationOperator, admin, driver, saccoAdmin }

class User {
  final String token;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? role;
  final String? stationName;
  final int? stationId;

  User({
    required this.token,
    this.fullName,
    this.phone,
    this.email,
    this.role,
    this.stationName,
    this.stationId,
  });

  UserRole? get userRole {
    if (role == null) return null;
    switch (role) {
      case 'station_operator':
        return UserRole.stationOperator;
      case 'admin':
      case 'super_admin':
      case 'ops':
      case 'finance':
      case 'safety':
        return UserRole.admin;
      case 'driver':
        return UserRole.driver;
      case 'sacco_admin':
        return UserRole.saccoAdmin;
      default:
        return null;
    }
  }

  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName![0].toUpperCase();
    }
    return 'U';
  }

  factory User.fromAdminJson(Map<String, dynamic> json, String token) {
    return User(
      token: token,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'admin',
    );
  }

  factory User.fromStationJson(Map<String, dynamic> json, String token) {
    return User(
      token: token,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: 'station_operator',
      stationName: json['station_name'] as String?,
      stationId: json['station_id'] as int?,
    );
  }

  factory User.fromDriverJson(Map<String, dynamic> json, String token) {
    return User(
      token: token,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: 'driver',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'role': role,
    'station_name': stationName,
    'station_id': stationId,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json['token'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      stationName: json['station_name'] as String?,
      stationId: json['station_id'] as int?,
    );
  }
}
