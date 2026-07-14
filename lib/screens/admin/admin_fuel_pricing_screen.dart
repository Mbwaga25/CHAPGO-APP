import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

/// Admin-configurable EWURA fuel prices (handbook §12.13).
/// Prices are stored server-side so they can change without an app release.
class AdminFuelPricingScreen extends StatefulWidget {
  const AdminFuelPricingScreen({super.key});

  @override
  State<AdminFuelPricingScreen> createState() => _AdminFuelPricingScreenState();
}

class _AdminFuelPricingScreenState extends State<AdminFuelPricingScreen> {
  final _api = ApiService();
  final _petrol = TextEditingController();
  final _cng = TextEditingController();
  final _electric = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _api.setToken(user.token);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _petrol.dispose();
    _cng.dispose();
    _electric.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await _api.get('/config/pricing');
      _petrol.text = '${r['petrol'] ?? ''}';
      _cng.text = '${r['cng'] ?? ''}';
      _electric.text = '${r['electric'] ?? ''}';
    } catch (e) {
      debugPrint('pricing load: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.put('/config/pricing', body: {
        'petrol': double.tryParse(_petrol.text.trim()) ?? 0,
        'cng': double.tryParse(_cng.text.trim()) ?? 0,
        'electric': double.tryParse(_electric.text.trim()) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Fuel prices updated'), backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Price Configuration')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.gold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'EWURA prices. Changes apply immediately to all income calculations across the platform.',
                          style: TextStyle(fontSize: 12, color: AppTheme.gray, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _priceField('Petrol (TZS / L)', _petrol, 'Bodaboda + Bajaji'),
                const SizedBox(height: 16),
                _priceField('CNG (TZS / kg)', _cng, 'Bajaji CNG'),
                const SizedBox(height: 16),
                _priceField('Electric (TZS / kWh)', _electric, 'Bajaji Electric'),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Prices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _priceField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
