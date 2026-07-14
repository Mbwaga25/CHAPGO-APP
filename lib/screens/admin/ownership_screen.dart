import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/ownership.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/metric_card.dart';

class OwnershipScreen extends StatefulWidget {
  const OwnershipScreen({super.key});

  @override
  State<OwnershipScreen> createState() => _OwnershipScreenState();
}

class _OwnershipScreenState extends State<OwnershipScreen> {
  OwnershipData? _data;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final api = ApiService()..setToken(user.token);
    try {
      final d = await api.get('/member/admin/total-units');
      if (!mounted) return;
      setState(() => _data = OwnershipData.fromJson(d));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Member Ownership Ledger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
              const SizedBox(height: 4),
              Text('Covenant Principle 1 — Every member is a real owner', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: MetricCard(label: 'Total Members', value: '${_data?.members ?? 0}')),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(label: 'Total Share Units', value: '${_data?.totalUnits ?? 0}')),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.soft,
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: AppTheme.gold, width: 4)),
          ),
          child: Text(
            'Covenant Note: Member share units are tracked immutably. They can be granted by Super Admin with reason logged, but never revoked except under Covenant procedure.',
            style: TextStyle(fontSize: 13, color: AppTheme.navy),
          ),
        ),
      ],
    );
  }
}
