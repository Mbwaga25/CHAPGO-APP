import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

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
  String _selectedCountryCode = '+255';

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

  String get _normalizedPhone {
    String raw = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) return '';
    if (raw.startsWith('+')) return raw;
    String codeDigits = _selectedCountryCode.replaceFirst('+', '');
    if (raw.startsWith(codeDigits)) return '+$raw';
    if (raw.startsWith('0')) return _selectedCountryCode + raw.substring(1);
    return _selectedCountryCode + raw;
  }

  bool _isValidPhone(String phone) {
    if (phone.startsWith('+255')) {
      return RegExp(r'^\+255\d{9}$').hasMatch(phone);
    }
    return RegExp(r'^\+\d{10,14}$').hasMatch(phone);
  }

  Future<void> _requestOtp() async {
    final lang = context.read<LanguageProvider>();
    final phone = _normalizedPhone;
    if (!_isValidPhone(phone)) {
      _showNotification(lang.translate('invalid_phone'), type: 'error');
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.sendOtp(phone);

    if (mounted) {
      if (auth.error == null) {
        _showNotification(lang.translate('otp_sent_success'), type: 'success');
        Navigator.pushNamed(context, '/otp-verify', arguments: {'phone': phone});
      } else {
        _showNotification(auth.error!, type: 'error');
      }
    }
  }

  Future<void> _loginWithPassword() async {
    final lang = context.read<LanguageProvider>();
    String credential = _emailController.text.trim();
    final password = _passwordController.text;

    if (credential.isEmpty || password.isEmpty) {
      _showNotification(lang.translate('fill_all_fields'), type: 'warning');
      return;
    }

    // Automatically normalize the credential if it looks like a phone number
    if (!credential.contains('@')) {
      String raw = credential.replaceAll(RegExp(r'\s+'), '');
      if (raw.startsWith('+')) {
        credential = raw;
      } else if (raw.startsWith('255')) {
        credential = '+$raw';
      } else if (raw.startsWith('0')) {
        credential = '+255' + raw.substring(1);
      } else if (RegExp(r'^\d+$').hasMatch(raw)) {
        credential = '+255' + raw;
      }
    }

    final auth = context.read<AuthProvider>();
    
    final success = await auth.login(credential, password);

    if (mounted) {
      if (success) {
        _showNotification(lang.translate('login_success'), type: 'success');
        _routeToDashboard(auth.user?.userRole);
      } else {
        _showNotification(auth.error ?? lang.translate('login_failed'), type: 'error');
      }
    }
  }

  void _routeToDashboard(UserRole? role) {
    String route;
    switch (role) {
      case UserRole.stationOperator:
        route = '/station/home';
      case UserRole.saccoAdmin:
        route = '/sacco/home';
      case UserRole.admin:
        route = '/admin/home';
      case UserRole.driver:
        route = '/driver/home';
      default:
        route = '/';
    }
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  void _showNotification(String message, {String type = 'success'}) {
    Color bgColor;
    IconData icon;
    switch (type) {
      case 'success':
        bgColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        break;
      case 'error':
        bgColor = Colors.red.shade600;
        icon = Icons.error_outline;
        break;
      case 'warning':
        bgColor = Colors.orange.shade700;
        icon = Icons.warning_amber_outlined;
        break;
      default:
        bgColor = Colors.blue.shade600;
        icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 90,
          left: 15,
          right: 15,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: () {
                        final newLocale = lang.locale == 'en' ? 'sw' : 'en';
                        lang.setLocale(newLocale);
                      },
                      icon: const Icon(Icons.language, color: AppTheme.navy, size: 18),
                      label: Text(
                        lang.locale == 'en' ? 'Kiswahili' : 'English',
                        style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                    tabs: [
                      Tab(text: lang.translate('phone_number_tab')),
                      Tab(text: lang.translate('password_tab')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _phoneTab(lang),
                        _emailTab(lang),
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
                          TextSpan(text: lang.translate('no_account')),
                          TextSpan(
                            text: lang.translate('register_now'),
                            style: const TextStyle(
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
      ),
    );
  }

  Widget _phoneTab(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('login_with_otp'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.navy),
        ),
        const SizedBox(height: 4),
        Text(lang.translate('otp_sms_note'), style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
        const SizedBox(height: 20),
        
        // Country Selector and Phone field row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  items: const [
                    DropdownMenuItem(value: '+255', child: Text('🇹🇿 +255')),
                    DropdownMenuItem(value: '+254', child: Text('🇰🇪 +254')),
                    DropdownMenuItem(value: '+256', child: Text('🇺🇬 +256')),
                    DropdownMenuItem(value: '+250', child: Text('🇷🇼 +250')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedCountryCode = v ?? '+255';
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: lang.translate('phone_field'),
                  hintText: lang.translate('phone_hint'),
                ),
              ),
            ),
          ],
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
                    : Text(lang.translate('send_otp')),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _emailTab(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('login_with_password'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.navy),
        ),
        const SizedBox(height: 4),
        Text(lang.translate('password_login_note'), style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: lang.translate('email_phone_field'),
            hintText: lang.translate('email_phone_hint'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: lang.translate('password_field'),
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
                    : Text(lang.translate('login_btn')),
              ),
            );
          },
        ),
      ],
    );
  }
}
