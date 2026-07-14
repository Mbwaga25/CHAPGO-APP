import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EnterScanScreen extends StatefulWidget {
  const EnterScanScreen({super.key});

  @override
  State<EnterScanScreen> createState() => _EnterScanScreenState();
}

class _EnterScanScreenState extends State<EnterScanScreen> {
  final _litersController = TextEditingController();
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _submitting = false;
  late final ApiService _api;
  String? _qrToken;

  final _paymentOptions = [
    ('cash', 'Cash'),
    ('mpesa', 'M-Pesa'),
    ('mixx', 'Mixx by Yas'),
    ('airtel_money', 'Airtel Money'),
    ('chapesa', 'Chapesa'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _qrToken = args?['qr_token'] as String?;
    _api = ApiService();
    final user = context.read<AuthProvider>().user;
    if (user != null) _api.setToken(user.token);
  }

  @override
  void dispose() {
    _litersController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final liters = double.tryParse(_litersController.text);
    final amount = int.tryParse(_amountController.text);

    if (liters == null || liters < 0.5 || liters > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lita lazima ziwe kati ya 0.5 na 100')),
      );
      return;
    }
    if (amount == null || amount < 500 || amount > 500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiasi lazima kiwe kati ya TSh 500 na 500,000')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await _api.post('/scans', body: {
        'qr_token': _qrToken,
        'liters': liters,
        'amount_tsh': amount,
        'payment_method': _paymentMethod,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/station/confirm',
          arguments: {
            'driver_name': result['scan']['driver_name'] ?? '—',
            'amount': amount,
            'liters': liters,
            'flagged': result['scan']['flagged'] ?? false,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindikana: $e')),
        );
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weka Mauzo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Weka lita na kiasi cha TSh',
              style: TextStyle(fontSize: 14, color: AppTheme.gray),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.soft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('QR Token', style: TextStyle(color: AppTheme.gray, fontSize: 13)),
                      Text(
                        _qrToken?.substring(0, 16) ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dereva atathibitishwa wakati wa kutuma scan',
                    style: TextStyle(fontSize: 12, color: AppTheme.gray),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _litersController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Lita za Mafuta',
                hintText: '0.0',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kiasi (TSh)',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Njia ya Malipo'),
              items: _paymentOptions.map((o) {
                return DropdownMenuItem(value: o.$1, child: Text(o.$2));
              }).toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text('Thibitisha Scan'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ghairi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
