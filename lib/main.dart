import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/cashflow_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/station/station_home_screen.dart';
import 'screens/station/scan_screen.dart';
import 'screens/station/manual_qr_screen.dart';
import 'screens/station/enter_scan_screen.dart';
import 'screens/station/confirm_screen.dart';
import 'screens/station/operators_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/driver_profile_screen.dart';
import 'screens/driver/driver_qr_screen.dart';
import 'screens/driver/driver_score_screen.dart';
import 'screens/driver/driver_loans_screen.dart';
import 'screens/driver/driver_notifications_screen.dart';
import 'screens/driver/driver_loans_list_screen.dart';
import 'screens/driver/driver_stations_map_screen.dart';
import 'screens/driver/driver_evaluation_report_screen.dart';
import 'screens/driver/driver_cashflow_page.dart';
import 'screens/driver/driver_delivery_screen.dart';
import 'screens/driver/driver_saccos_screen.dart';
import 'screens/sacco/sacco_home_screen.dart';
import 'widgets/auth_gate.dart';
import 'models/user.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.checkHostFallback();
  runApp(const ChapgoApp());
}

class ChapgoApp extends StatelessWidget {
  const ChapgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final authService = AuthService(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService)..tryAutoLogin(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CashflowProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
        title: 'Chapgo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              );

            // Auth
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              );
            case '/register':
              return MaterialPageRoute(
                builder: (_) => const RegisterScreen(),
              );
            case '/otp-verify':
              return MaterialPageRoute(
                builder: (_) => const OtpVerificationScreen(),
              );

            // Station
            case '/station/home':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.stationOperator, child: StationHomeScreen()),
              );
            case '/station/scan':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.stationOperator, child: ScanScreen()),
              );
            case '/station/manual-qr':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.stationOperator, child: ManualQrScreen()),
              );
            case '/station/enter-scan':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.stationOperator, child: EnterScanScreen()),
              );
            case '/station/confirm':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.stationOperator, child: ConfirmScreen()),
              );
            case '/station/operators':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.stationOperator, child: OperatorsScreen()),
              );

            // Admin
            case '/admin/home':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.admin, child: AdminHomeScreen()),
              );

            // Driver
            case '/driver/home':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverHomeScreen()),
              );
            case '/driver/profile':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverProfileScreen()),
              );
            case '/driver/qr-code':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverQrScreen()),
              );
            case '/driver/score':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverScoreScreen()),
              );
            case '/driver/loans':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => AuthGate(
                  role: UserRole.driver,
                  child: DriverLoansScreen(
                    saccoId: args?['sacco_id'] as String?,
                    saccoName: args?['sacco_name'] as String?,
                  ),
                ),
              );
            case '/driver/notifications':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverNotificationsScreen()),
                settings: settings,
              );
            case '/driver/loans/list':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverLoansListScreen()),
                settings: settings,
              );
            case '/driver/stations/map':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverStationsMapScreen()),
                settings: settings,
              );
            case '/driver/reports/evaluation':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverEvaluationReportScreen()),
                settings: settings,
              );
            case '/driver/cashflow':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverCashflowPage()),
                settings: settings,
              );
            case '/driver/delivery':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverDeliveryScreen()),
                settings: settings,
              );
            case '/driver/saccos':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.driver, child: DriverSaccosScreen()),
                settings: settings,
              );
            case '/sacco/home':
              return MaterialPageRoute(
                builder: (_) => const AuthGate(role: UserRole.saccoAdmin, child: SaccoHomeScreen()),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              );
          }
        },
        ),
      ),
    );
  }
}
