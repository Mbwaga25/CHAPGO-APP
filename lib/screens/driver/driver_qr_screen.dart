import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/driver_subpage_navbar.dart';

class DriverQrScreen extends StatelessWidget {
  const DriverQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('My QR Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show this QR at fuel stations',
                style: TextStyle(fontSize: 16, color: AppTheme.navy),
              ),
              const SizedBox(height: 8),
              Text(
                'Station operators will scan to record your fuel purchase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.gray),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gold, width: 2),
                ),
                child: QrImageView(
                  data: user?.phone ?? 'chapgo_driver_unknown',
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const DriverSubPageNavBar(activeIndex: -1),
    );
  }
}
