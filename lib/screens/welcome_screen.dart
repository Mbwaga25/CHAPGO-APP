import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/chapgo_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.4, end: 1.0));
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _contentSlide = CurvedAnimation(parent: _contentController, curve: Curves.easeOut)
        .drive(Tween(begin: const Offset(0, 0.3), end: Offset.zero));
    _contentFade = CurvedAnimation(parent: _contentController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoController.forward().then((_) {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _routeToDashboard(BuildContext context, UserRole? role) {
    String route;
    switch (role) {
      case UserRole.stationOperator:
        route = '/station/home';
        break;
      case UserRole.saccoAdmin:
        route = '/sacco/home';
        break;
      case UserRole.admin:
        route = '/admin/home';
        break;
      case UserRole.driver:
        route = '/driver/home';
        break;
      default:
        route = '/';
        return;
    }
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _routeToDashboard(context, auth.user?.userRole);
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ─── Background gradient ─────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF1E3A5F), // deep blue
                  Color(0xFF0F172A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ─── Decorative circles ──────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.07),
              ),
            ),
          ),

          // ─── Content ─────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const ChapgoLogo(),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // CTA Buttons
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        children: [
                          // Feature pills
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _featurePill(Icons.account_balance_wallet, 'Cashflow'),
                              _featurePill(Icons.star_rate, 'Boda Score'),
                              _featurePill(Icons.local_gas_station, 'Fuel Credit'),
                              _featurePill(Icons.assignment, 'Microloans'),
                            ],
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gold,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Ingia',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_forward, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Footer
                  Text(
                    'Chapgo Company Limited',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.goldLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
