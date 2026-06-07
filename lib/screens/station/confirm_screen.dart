import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  String _driverName = '';
  int _amount = 0;
  double _liters = 0;
  bool _flagged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _driverName = args['driver_name'] as String? ?? '';
      _amount = int.tryParse(args['amount']?.toString() ?? '') ?? 0;
      _liters = double.tryParse(args['liters']?.toString() ?? '') ?? 0.0;
      _flagged = args['flagged'] as bool? ?? false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_flagged) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Text('⚠️ '),
                Text('Tahadhari'),
              ],
            ),
            content: const Text(
              'Gari hili limeripotiwa. Ofisi ya usalama inapigwa simu sasa. Endelea kawaida lakini usionyeshe hofu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Sawa'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EB),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(left: BorderSide(color: AppTheme.green, width: 4)),
                ),
                child: const Column(
                  children: [
                    Text('✅', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 8),
                    Text(
                      'Scan Imefanikiwa!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _DetailCard(label: 'Dereva', value: _driverName),
              const SizedBox(height: 8),
              _DetailCard(label: 'Mauzo', value: 'TSh $_amount'),
              const SizedBox(height: 8),
              _DetailCard(label: 'Lita', value: '${_liters.toStringAsFixed(2)} L'),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/station/scan',
                      (route) => route.settings.name == '/station/home',
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Nyingine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamedAndRemoveUntil(context, '/station/home', (_) => false),
                  child: const Text('Rudi Nyumbani'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;

  const _DetailCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppTheme.gold, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}
