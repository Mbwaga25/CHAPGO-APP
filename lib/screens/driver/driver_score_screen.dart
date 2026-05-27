import 'package:flutter/material.dart';
import '../../config/theme.dart';

class DriverScoreScreen extends StatelessWidget {
  const DriverScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boda Score')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: AppTheme.grayLight),
              SizedBox(height: 16),
              Text(
                'Boda Score',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy),
              ),
              SizedBox(height: 8),
              Text(
                'Your Boda Score and detailed credit history will be available here soon. Keep scanning fuel to build your score!',
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
