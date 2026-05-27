import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/tithe.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_badge.dart';

class TitheScreen extends StatefulWidget {
  const TitheScreen({super.key});

  @override
  State<TitheScreen> createState() => _TitheScreenState();
}

class _TitheScreenState extends State<TitheScreen> {
  TitheTotals? _totals;
  List<TitheTransaction> _transactions = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final api = ApiService()..setToken(user.token);
    setState(() => _loading = true);
    try {
      final t = await api.get('/tithe/admin/totals');
      final l = await api.get('/tithe/admin/ledger');
      setState(() {
        _totals = TitheTotals.fromJson(t);
        _transactions = (l['transactions'] as List?)?.map((x) => TitheTransaction.fromJson(x)).toList() ?? [];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _tsh(num n) => 'TSh ${n.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Corporate Tithe Ledger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                SizedBox(height: 4),
                Text('Covenant Principle 6 — 10% of profit to Kingdom work', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
              ],
            ),
          ),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              SizedBox(width: _cardWidth, child: MetricCard(label: 'Transferred (cumulative)', value: _tsh(_totals?.transferredTsh ?? 0))),
              SizedBox(width: _cardWidth, child: MetricCard(label: 'Pending Transfer', value: _tsh(_totals?.pendingTsh ?? 0), isCritical: true)),
              SizedBox(width: _cardWidth, child: MetricCard(label: 'Total Transactions', value: '${_totals?.totalTransactions ?? 0}')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tithe Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_transactions.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No transactions yet', style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)))))
          else
            ..._transactions.map((x) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(x.subsidiary, style: const TextStyle(fontWeight: FontWeight.w600)),
                        StatusBadge(label: x.transferStatus, variant: x.transferStatus == 'transferred' ? BadgeVariant.active : BadgeVariant.pending),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${x.periodStart} — ${x.periodEnd}', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Profit: ${_tsh(x.subsidiaryProfitTsh)}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        Text('Tithe: ${_tsh(x.titheAmountTsh)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('Destination: ${x.destination}', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  double get _cardWidth {
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return (w - 48) / 3 - 12;
    return w - 32;
  }
}
