import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/dashboard.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/metric_card.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  DashboardMetrics? _metrics;
  bool _loading = true;
  String? _error;

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
    setState(() => _loading = true);

    try {
      final endpoint = user.userRole == UserRole.saccoAdmin 
          ? '/sacco/overview' 
          : '/admin/dashboard';
      final data = await api.get(endpoint);
      setState(() {
        _metrics = DashboardMetrics.fromJson(data);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final m = _metrics!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy),
                ),
                const SizedBox(height: 4),
                Text(
                  m.isSacco
                      ? 'Real-time operational metrics for your SACCO'
                      : 'Real-time operational metrics across Chapgo',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: m.isSacco
                ? [
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(label: 'Active Members', value: '${m.activeMembers}'),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(
                        label: 'Collections (30d)',
                        value: 'TSh ${m.collections30d.toStringAsFixed(0)}',
                      ),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(label: 'Active Loans', value: '${m.activeLoansCount}'),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(
                        label: 'Active Loans Value',
                        value: 'TSh ${m.activeLoansValue.toStringAsFixed(0)}',
                      ),
                    ),
                  ]
                : [
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(label: 'Total Members', value: '${m.drivers}'),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(label: 'Active Stations', value: '${m.stations}'),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(label: 'Active SACCOs', value: '${m.saccos}'),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(
                        label: 'Scans (30d)',
                        value: m.scansLast30Days.toString(),
                      ),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(label: 'Active Loans', value: '${m.activeLoans}'),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(
                        label: 'Active Watchlist',
                        value: '${m.activeWatchlist}',
                        isCritical: m.activeWatchlist > 0,
                      ),
                    ),
                    SizedBox(
                      width: _cardWidth,
                      child: MetricCard(
                        label: 'Open Escalations',
                        value: '${m.openEscalations}',
                        isCritical: m.openEscalations > 0,
                      ),
                    ),
                  ],
          ),
          if (!m.isSacco) ...[
            const SizedBox(height: 24),
            Text(
              'Critical Alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),
            if (m.openEscalations == 0 && m.activeWatchlist == 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No critical alerts. System is healthy.',
                      style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              )
            else ...[
              if (m.openEscalations > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E8E8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border(left: BorderSide(color: AppTheme.red, width: 4)),
                  ),
                  child: Text(
                    '${m.openEscalations} members waiting for human support',
                    style: TextStyle(color: AppTheme.red),
                  ),
                ),
              if (m.activeWatchlist > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E8E8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border(left: BorderSide(color: AppTheme.red, width: 4)),
                  ),
                  child: Text(
                    '${m.activeWatchlist} vehicles on active theft watchlist',
                    style: TextStyle(color: AppTheme.red),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  double get _cardWidth {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return (width - 48) / 3 - 12;
    if (width > 400) return (width - 32) / 2 - 6;
    return width - 32;
  }
}
