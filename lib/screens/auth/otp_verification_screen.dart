import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final phone = args['phone'] as String;
    final code = _otpController.text.trim();

    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP ina tarakimu 6')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    bool success = await auth.stationOtpLogin(phone, code);
    if (!success) {
      success = await auth.driverOtpLogin(phone, code);
    }

    if (mounted && success) {
      _routeToDashboard(auth.user?.userRole);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'OTP si sahihi')),
      );
    }
  }

  void _routeToDashboard(UserRole? role) {
    String route;
    switch (role) {
      case UserRole.stationOperator:
        route = '/station/home';
      case UserRole.admin:
      case UserRole.saccoAdmin:
        route = '/admin/home';
      case UserRole.driver:
        route = '/driver/home';
      default:
        route = '/';
    }
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final phone = args?['phone'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Weka OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),
            Text(
              'OTP ilitumwa kwa $phone',
              style: TextStyle(fontSize: 14, color: AppTheme.gray),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Namba ya OTP (tarakimu 6)',
                hintText: '______',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.status == AuthStatus.loading ? null : _verifyOtp,
                    child: auth.status == AuthStatus.loading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                        : const Text('Thibitisha'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Rudi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
