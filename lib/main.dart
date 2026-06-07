import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/cashflow_provider.dart';
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
import 'screens/sacco/sacco_home_screen.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'Chapgo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
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
                builder: (_) => const StationHomeScreen(),
              );
            case '/station/scan':
              return MaterialPageRoute(
                builder: (_) => const ScanScreen(),
              );
            case '/station/manual-qr':
              return MaterialPageRoute(
                builder: (_) => const ManualQrScreen(),
              );
            case '/station/enter-scan':
              return MaterialPageRoute(
                builder: (_) => const EnterScanScreen(),
              );
            case '/station/confirm':
              return MaterialPageRoute(
                builder: (_) => const ConfirmScreen(),
              );
            case '/station/operators':
              return MaterialPageRoute(
                builder: (_) => const OperatorsScreen(),
              );

            // Admin
            case '/admin/home':
              return MaterialPageRoute(
                builder: (_) => const AdminHomeScreen(),
              );

            // Driver
            case '/driver/home':
              return MaterialPageRoute(
                builder: (_) => const DriverHomeScreen(),
              );
            case '/driver/profile':
              return MaterialPageRoute(
                builder: (_) => const DriverProfileScreen(),
              );
            case '/driver/qr-code':
              return MaterialPageRoute(
                builder: (_) => const DriverQrScreen(),
              );
            case '/driver/score':
              return MaterialPageRoute(
                builder: (_) => const DriverScoreScreen(),
              );
            case '/driver/loans':
              return MaterialPageRoute(
                builder: (_) => const DriverLoansScreen(),
              );
            case '/driver/notifications':
              return MaterialPageRoute(
                builder: (_) => const DriverNotificationsScreen(),
                settings: settings,
              );
            case '/driver/loans/list':
              return MaterialPageRoute(
                builder: (_) => const DriverLoansListScreen(),
                settings: settings,
              );
            case '/driver/stations/map':
              return MaterialPageRoute(
                builder: (_) => const DriverStationsMapScreen(),
                settings: settings,
              );
            case '/driver/reports/evaluation':
              return MaterialPageRoute(
                builder: (_) => const DriverEvaluationReportScreen(),
                settings: settings,
              );
            case '/driver/cashflow':
              return MaterialPageRoute(
                builder: (_) => const DriverCashflowPage(),
                settings: settings,
              );
            case '/sacco/home':
              return MaterialPageRoute(
                builder: (_) => const SaccoHomeScreen(),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              );
          }
        },
      ),
    );
  }
}
