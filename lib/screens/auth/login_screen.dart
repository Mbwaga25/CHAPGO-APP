import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+255\d{9}$').hasMatch(phone);
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (!_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Namba ya simu si sahihi. Mfano: +255712345678')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.sendOtp(phone);

    if (mounted) {
      Navigator.pushNamed(context, '/otp-verify', arguments: {'phone': phone});
    }
  }

  Future<void> _loginWithPassword() async {
    final credential = _emailController.text.trim();
    final password = _passwordController.text;

    if (credential.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali jaza taarifa zote')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    
    bool success = false;
    if (_isValidPhone(credential)) {
      success = await auth.stationPasswordLogin(credential, password);
      if (!success) {
        success = await auth.driverPasswordLogin(credential, password);
      }
    } else {
      success = await auth.adminLogin(credential, password);
    }

    if (mounted && success) {
      _routeToDashboard(auth.user?.userRole);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Ingia imeshindikana')),
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
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.gold,
                  child: Text('C', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.white)),
                ),
                const SizedBox(height: 16),
                const Text('Chapgo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text('Zamunda Holdings Limited', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
                const SizedBox(height: 32),
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.navy,
                  unselectedLabelColor: AppTheme.grayLight,
                  indicatorColor: AppTheme.gold,
                  tabs: const [
                    Tab(text: 'Namba ya Simu'),
                    Tab(text: 'Nenosiri'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 260,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _phoneTab(),
                      _emailTab(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: AppTheme.gray),
                      children: [
                        const TextSpan(text: 'Huna akaunti? '),
                        TextSpan(
                          text: 'Sajili sasa',
                          style: TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingia kwa OTP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.navy),
        ),
        const SizedBox(height: 4),
        Text('Tutakutumia OTP kwa SMS', style: TextStyle(fontSize: 13, color: AppTheme.gray)),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Namba ya simu',
            hintText: '+255712345678',
          ),
        ),
        const SizedBox(height: 20),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.status == AuthStatus.loading ? null : _requestOtp,
                child: auth.status == AuthStatus.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                    : const Text('Tuma OTP'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _emailTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingia kwa nenosiri',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.navy),
        ),
        const SizedBox(height: 4),
        Text('Tumia namba ya simu au barua pepe na nenosiri', style: TextStyle(fontSize: 13, color: AppTheme.gray)),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Namba ya Simu au Barua pepe',
            hintText: '+2557... au admin@chapgo.co.tz',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Nenosiri',
            hintText: '••••••••••••',
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.gray),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.status == AuthStatus.loading ? null : _loginWithPassword,
                child: auth.status == AuthStatus.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                    : const Text('Ingia'),
              ),
            );
          },
        ),
      ],
    );
  }
}
