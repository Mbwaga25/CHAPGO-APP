import 'package:flutter/material.dart';
import '../../config/theme.dart';

class DriverLoansScreen extends StatelessWidget {
  const DriverLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Loans')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: AppTheme.grayLight),
              SizedBox(height: 16),
              Text(
                'Loans',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy),
              ),
              SizedBox(height: 8),
              Text(
                'Loan applications and history will be available here soon. Your Boda Score determines your loan eligibility.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.gray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
