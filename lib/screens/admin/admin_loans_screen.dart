import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class AdminLoansScreen extends StatefulWidget {
  const AdminLoansScreen({super.key});

  @override
  State<AdminLoansScreen> createState() => _AdminLoansScreenState();
}

class _AdminLoansScreenState extends State<AdminLoansScreen> {
  final _api = ApiService();
  List<dynamic> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLoans();
      }
    });
  }

  Future<void> _loadLoans() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/loans');
      setState(() {
        _loans = res['loans'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindikana kupakia mikopo: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  BadgeVariant _getVariant(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BadgeVariant.active;
      case 'pending':
        return BadgeVariant.pending;
      case 'settled':
        return BadgeVariant.active;
      case 'defaulted':
        return BadgeVariant.urgent;
      default:
        return BadgeVariant.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: _loans.isEmpty
          ? const Center(
              child: Text(
                'Hakuna mikopo iliyosajiliwa',
                style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _loans.length,
              itemBuilder: (ctx, idx) {
                final l = _loans[idx];
                final driver = l['driver_name'] ?? '';
                final plate = l['vehicle_plate'] ?? '';
                final sacco = l['sacco_name'] ?? '—';
                final amount = double.tryParse(l['amount_tsh']?.toString() ?? '0') ?? 0;
                final term = l['term_months'] ?? 0;
                final status = l['status'] ?? 'pending';
                final missed = l['missed_payments_count'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(driver, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy)),
                            StatusBadge(
                              label: status.toUpperCase(),
                              variant: _getVariant(status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Chombo: $plate  ·  SACCO: $sacco', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statColumn('Kiasi cha Mkopo', 'TSh ${amount.toStringAsFixed(0)}'),
                            _statColumn('Muda wa Mkopo', '$term miezi'),
                            _statColumn('Malipo Yasiyofanyika', '$missed', isCritical: missed > 0),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statColumn(String label, String value, {bool isCritical = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isCritical ? AppTheme.red : AppTheme.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
