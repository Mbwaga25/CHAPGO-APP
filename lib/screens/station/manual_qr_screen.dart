import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ManualQrScreen extends StatefulWidget {
  const ManualQrScreen({super.key});

  @override
  State<ManualQrScreen> createState() => _ManualQrScreenState();
}

class _ManualQrScreenState extends State<ManualQrScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final token = _controller.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali andika QR token')),
      );
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      '/station/enter-scan',
      arguments: {'qr_token': token},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingiza QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Ingiza QR Code',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Andika QR token ya dereva kama kamera haifanyi kazi',
              style: TextStyle(fontSize: 14, color: AppTheme.gray),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'QR Token',
                hintText: 'Andika token...',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Endelea'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Rudi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
