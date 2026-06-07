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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedCountryCode = '+255';
  OverlayEntry? _activeOverlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _activeOverlay?.remove();
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

  void _quickLogin(String username, String password) {
    setState(() {
      _tabController.index = 1;
      _emailController.text = username;
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
                boxShadow: [
                  BoxShadow(color: bgColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
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
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // ─── Gradient Header ──────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 32,
              bottom: 36,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              ),
            ),
            child: Column(
              children: [
                // Language toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final newLocale = lang.locale == 'en' ? 'sw' : 'en';
                        lang.setLocale(newLocale);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              lang.locale == 'en' ? 'Kiswahili' : 'English',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.gold, AppTheme.goldDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.motorcycle, size: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chapgo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zamunda Holdings Limited',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),

          // ─── Form Body ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab switcher
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.gray,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppTheme.navy,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.navy.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          tabs: [
                            Tab(text: lang.translate('phone_number_tab')),
                            Tab(text: lang.translate('password_tab')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 280,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _phoneTab(lang),
                            _emailTab(lang),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
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
                      ),

                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Demo quick login
                      const Center(
                        child: Text(
                          'DEMO QUICK LOGIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.grayLight,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _quickLoginChip(
                            'Super Admin',
                            Icons.shield,
                            const Color(0xFF7C3AED),
                            () => _quickLogin('admin@zamunda.co.tz', 'password'),
                          ),
                          _quickLoginChip(
                            'SACCO Admin',
                            Icons.business,
                            AppTheme.accent,
                            () => _quickLogin('+255756000001', 'password'),
                          ),
                          _quickLoginChip(
                            'Station Op.',
                            Icons.local_gas_station,
                            AppTheme.teal,
                            () => _quickLogin('+255756000002', 'password'),
                          ),
                          _quickLoginChip(
                            'Driver',
                            Icons.motorcycle,
                            AppTheme.gold,
                            () => _quickLogin('+255711000001', 'password'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickLoginChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 4),
        Text(lang.translate('otp_sms_note'),
            style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 1.5),
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
                  onChanged: (v) => setState(() => _selectedCountryCode = v ?? '+255'),
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
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: auth.status == AuthStatus.loading ? null : _requestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: auth.status == AuthStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                    )
                  : Text(lang.translate('send_otp')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emailTab(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.translate('login_with_password'), style: AppTheme.headingMedium),
        const SizedBox(height: 4),
        Text(lang.translate('password_login_note'),
            style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: lang.translate('email_phone_field'),
            hintText: lang.translate('email_phone_hint'),
            prefixIcon: const Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: lang.translate('password_field'),
            hintText: '••••••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.gray,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: auth.status == AuthStatus.loading ? null : _loginWithPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: auth.status == AuthStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                    )
                  : Text(lang.translate('login_btn')),
            ),
          ),
        ),
      ],
    );
  }
}
