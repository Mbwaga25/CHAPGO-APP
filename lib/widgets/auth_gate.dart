import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class AuthGate extends StatelessWidget {
  final Widget child;
  final UserRole? role;

  const AuthGate({super.key, required this.child, this.role});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Show loading indicator while app is initializing or running auto-login
    if (auth.status == AuthStatus.uninitialized || auth.status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Redirect to welcome/login if not authenticated
    if (auth.status == AuthStatus.unauthenticated || auth.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 3. Optional role-based checks
    if (role != null && auth.role != role) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return child;
  }
}
