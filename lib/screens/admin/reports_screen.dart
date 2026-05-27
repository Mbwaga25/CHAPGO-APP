import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/report.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<QuarterlyReport> _reports = [];
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
      final r = await api.get('/reports/rc-quarterly');
      setState(() {
        _reports = (r['reports'] as List?)?.map((x) => QuarterlyReport.fromJson(x)).toList() ?? [];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateReport() async {
    final quarterCtl = TextEditingController();
    final yearCtl = TextEditingController(text: DateTime.now().year.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate New Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: quarterCtl, decoration: const InputDecoration(labelText: 'Quarter (1-4)'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: yearCtl, decoration: const InputDecoration(labelText: 'Year'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final q = int.tryParse(quarterCtl.text);
              final y = int.tryParse(yearCtl.text);
              if (q == null || q < 1 || q > 4 || y == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quarter must be 1-4 and year valid')));
                return;
              }
              Navigator.pop(ctx);
              final user = context.read<AuthProvider>().user;
              if (user == null) return;
              final api = ApiService()..setToken(user.token);
              try {
                await api.post('/reports/rc-quarterly/generate', body: {'quarter': q, 'year': y});
                _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _markDelivered(int id) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final api = ApiService()..setToken(user.token);
    try {
      await api.post('/reports/rc-quarterly/$id/delivered');
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

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
                Text('RC Quarterly Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                SizedBox(height: 4),
                Text('Quarterly reports delivered to RC Dar es Salaam office', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Generated Reports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
              ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Generate New Report', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_reports.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No reports generated yet', style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)))))
          else
            ..._reports.map((r) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Q${r.quarterNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(width: 8),
                              Text('${r.reportYear}', style: const TextStyle(fontSize: 14, color: AppTheme.gray)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${r.periodStart} — ${r.periodEnd}', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                          const SizedBox(height: 4),
                          Text('Members: ${r.totalMembers} · Scans: ${r.totalScans}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(
                          label: r.isDelivered ? 'Delivered' : 'Pending',
                          variant: r.isDelivered ? BadgeVariant.active : BadgeVariant.pending,
                        ),
                        if (!r.isDelivered) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _markDelivered(r.id),
                            child: const Text('Mark Delivered', style: TextStyle(fontSize: 11, color: AppTheme.green)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}
