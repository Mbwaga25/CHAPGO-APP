import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/alert.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  List<TheftAlert> _alerts = [];
  List<WatchlistItem> _watchlist = [];
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
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final alertsData = await api.get('/safety/alerts?hours=48');
      final watchlistData = await api.get('/safety/watchlist');
      if (!mounted) return;
      setState(() {
        _alerts = (alertsData['alerts'] as List?)?.map((a) => TheftAlert.fromJson(a)).toList() ?? [];
        _watchlist = (watchlistData['watchlist'] as List?)?.map((w) => WatchlistItem.fromJson(w)).toList() ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markNotified(int alertId) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final api = ApiService()..setToken(user.token);
    try {
      await api.post('/safety/alerts/$alertId/notified', body: {'channel': 'owner'});
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
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
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ripoti Wizi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text('Active watchlist and recent theft alerts', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
              ],
            ),
          ),
          _SectionHeader(title: 'Theft Alerts (last 48 hours)', onRefresh: _loadData),
          if (_alerts.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No recent alerts', style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)))))
          else
            ..._alerts.map((a) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.vehiclePlate, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(a.stationName ?? '—', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                          Text(_formatDate(a.detectedAt), style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                          Row(
                            children: [
                              Text(a.isNotified ? '✅ Notified' : '❌ Not notified', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              const StatusBadge(label: 'Active', variant: BadgeVariant.urgent),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!a.isNotified)
                      TextButton(
                        onPressed: () => _markNotified(a.id),
                        child: Text('Mark Notified', style: TextStyle(fontSize: 12, color: AppTheme.green)),
                      ),
                  ],
                ),
              ),
            )),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Active Watchlist', onRefresh: null),
          if (_watchlist.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Watchlist is empty', style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)))))
          else
            ..._watchlist.map((w) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(w.vehiclePlate, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ref: ${w.referenceNumber ?? '—'}', style: const TextStyle(fontSize: 12)),
                    Text('Location: ${w.lastKnownLocation ?? '—'}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Text(w.reporterPhone ?? '', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
              ),
            )),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;
  const _SectionHeader({required this.title, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
        if (onRefresh != null)
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
