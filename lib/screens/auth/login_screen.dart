import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/chapgo_logo.dart';

// Fixed dark palette mirroring the Chapgo login prototype (Chapgo_Login.html)
class _C {
  static const dark = Color(0xFF061220);
  static const navy = Color(0xFF0B1D2E);
  static const gold = Color(0xFFD4A843);
  static const green = Color(0xFF1B7A4A);
  static const white = Color(0xFFF8F6F1);
  static const grey = Color(0xFF8899AA);
  static const greyLight = Color(0xFFB0BFCF);
  static const card = Color(0x0AFFFFFF);
  static const border = Color(0x1AFFFFFF);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _usePassword = false; // false = OTP, true = password alternative
  String _selectedRole = 'driver';
  String _selectedVehicleType = 'bodaboda-petrol';
  static const String _countryCode = '+255';
  OverlayEntry? _activeOverlay;

  @override
  void dispose() {
    _activeOverlay?.remove();
    _phoneController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    String raw = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) return '';
    if (raw.startsWith('+')) return raw;
    if (raw.startsWith('255')) return '+$raw';
    if (raw.startsWith('0')) return _countryCode + raw.substring(1);
    return _countryCode + raw;
  }

  bool _isValidPhone(String phone) => RegExp(r'^\+255\d{9}$').hasMatch(phone);

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
        Navigator.pushNamed(context, '/otp-verify',
            arguments: {'phone': phone, 'role': _selectedRole, 'vehicle_type': _selectedVehicleType});
      } else {
        _showNotification(auth.error!, type: 'error');
      }
    }
  }

  Future<void> _loginWithPassword() async {
    final lang = context.read<LanguageProvider>();
    String credential = _identifierController.text.trim();
    final password = _passwordController.text;

    if (credential.isEmpty || password.isEmpty) {
      _showNotification(lang.translate('fill_all_fields'), type: 'warning');
      return;
    }

    if (!credential.contains('@')) {
      String raw = credential.replaceAll(RegExp(r'\s+'), '');
      if (raw.startsWith('+')) {
        credential = raw;
      } else if (raw.startsWith('255')) {
        credential = '+$raw';
      } else if (raw.startsWith('0')) {
        credential = '+255${raw.substring(1)}';
      } else if (RegExp(r'^\d+$').hasMatch(raw)) {
        credential = '+255$raw';
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

  void _quickLogin(String username, String password) {
    setState(() {
      _usePassword = true;
      _identifierController.text = username;
      _passwordController.text = password;
    });
    _loginWithPassword();
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
        bgColor = AppTheme.green;
        icon = Icons.check_circle_outline;
        break;
      case 'error':
        bgColor = AppTheme.red;
        icon = Icons.error_outline;
        break;
      case 'warning':
        bgColor = AppTheme.orange;
        icon = Icons.warning_amber_outlined;
        break;
      default:
        bgColor = AppTheme.accent;
        icon = Icons.info_outline;
    }

    _activeOverlay?.remove();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 15,
        right: 15,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 470),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (entry.mounted) {
                        entry.remove();
                        if (_activeOverlay == entry) _activeOverlay = null;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _activeOverlay = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
        if (_activeOverlay == entry) _activeOverlay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final en = lang.locale == 'en';
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _routeToDashboard(auth.user?.userRole);
      });
      return const Scaffold(
        backgroundColor: _C.dark,
        body: Center(child: CircularProgressIndicator(color: _C.gold)),
      );
    }

    return Scaffold(
      backgroundColor: _C.dark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Top row: lang toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => lang.setLocale(en ? 'sw' : 'en'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _C.border),
                          ),
                          child: Text(en ? 'SW' : 'EN',
                              style: const TextStyle(
                                  color: _C.greyLight, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logo block
                  const ChapgoLogo(scale: 0.85, showSubtitle: false),
                  const SizedBox(height: 22),

                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _C.navy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(en ? 'Sign In' : 'Ingia',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _C.white)),
                        const SizedBox(height: 4),
                        Text(
                          _usePassword
                              ? (en ? 'Sign in with your password' : 'Ingia kwa nenosiri lako')
                              : (en ? 'Enter your registered phone number' : 'Weka namba yako ya simu iliyosajiliwa'),
                          style: const TextStyle(fontSize: 13, color: _C.grey),
                        ),
                        const SizedBox(height: 20),

                        // Credential inputs
                        if (_usePassword) ...[
                          _label(en ? 'Phone or Email' : 'Simu au Barua pepe'),
                          const SizedBox(height: 6),
                          _darkField(_identifierController,
                              hint: en ? '+2557… or you@email.com' : '+2557… au wewe@barua.com',
                              keyboard: TextInputType.text),
                          const SizedBox(height: 14),
                          _label(en ? 'Password' : 'Nenosiri'),
                          const SizedBox(height: 6),
                          _darkField(_passwordController,
                              hint: '••••••••',
                              obscure: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: _C.grey, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              )),
                        ] else ...[
                          _label(en ? 'Phone Number' : 'Namba ya Simu'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                decoration: BoxDecoration(
                                  color: _C.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _C.border),
                                ),
                                child: const Text('+255',
                                    style: TextStyle(color: _C.white, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _darkField(_phoneController,
                                    hint: '7XX XXX XXX', keyboard: TextInputType.phone),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Primary button
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            final loading = auth.status == AuthStatus.loading;
                            return SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: loading ? null : (_usePassword ? _loginWithPassword : _requestOtp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _C.gold,
                                  foregroundColor: _C.dark,
                                  disabledBackgroundColor: _C.gold.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _C.dark))
                                    : Text(
                                        _usePassword
                                            ? (en ? 'Sign In' : 'Ingia')
                                            : (en ? 'Send OTP' : 'Tuma OTP'),
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: _C.dark, fontSize: 16)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Toggle OTP <-> Password
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _usePassword = !_usePassword),
                            child: Text(
                              _usePassword
                                  ? (en ? 'Use OTP instead' : 'Tumia OTP badala yake')
                                  : (en ? 'Use password instead' : 'Tumia nenosiri badala yake'),
                              style: const TextStyle(color: _C.gold, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: _C.grey),
                        children: [
                          TextSpan(text: lang.translate('no_account')),
                          TextSpan(
                            text: lang.translate('register_now'),
                            style: const TextStyle(color: _C.gold, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Demo quick login
                  Container(height: 1, color: _C.border),
                  const SizedBox(height: 14),
                  Text(en ? 'DEMO QUICK LOGIN' : 'INGIA HARAKA (DEMO)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.grey, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _quickLoginChip('Super Admin', Icons.shield, const Color(0xFF8B5CF6),
                          () => _quickLogin('admin@zamunda.co.tz', 'password')),
                      _quickLoginChip('SACCO Admin', Icons.business, AppTheme.accent,
                          () => _quickLogin('+255756000001', 'password')),
                      _quickLoginChip('Station Op.', Icons.local_gas_station, AppTheme.teal,
                          () => _quickLogin('+255756000002', 'password')),
                      _quickLoginChip('Driver', Icons.motorcycle, _C.gold,
                          () => _quickLogin('+255711000001', 'password')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('CHAPGO · Phase 1 Pilot',
                      style: TextStyle(fontSize: 10, color: _C.grey, letterSpacing: 1)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontSize: 12, color: _C.greyLight, fontWeight: FontWeight.w600));

  Widget _darkField(TextEditingController controller,
      {String? hint, bool obscure = false, TextInputType? keyboard, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: _C.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.grey),
        filled: true,
        fillColor: _C.card,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.gold, width: 1.5)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
      ),
    );
  }

  Widget _quickLoginChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
