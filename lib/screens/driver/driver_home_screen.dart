import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

import '../../models/scan.dart';
import '../../services/api_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _api = ApiService();
  DailySummary? _summary;
  List<Scan> _history = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user != null) _api.setToken(user.token);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final historyData = await _api.get('/scan/my-history?days=30');
      setState(() {
        _summary = DailySummary.fromJson(historyData['totals'] ?? {});
        _history = (historyData['scans'] as List?)
                ?.map((s) => Scan.fromJson(s))
                .toList() ??
            [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapgo Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.gold,
                  child: Text(
                    user?.initials ?? 'D',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Driver',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                      ),
                      Text(
                        user?.phone ?? '',
                        style: const TextStyle(fontSize: 14, color: AppTheme.gray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _MenuCard(
              icon: '👤',
              title: 'My Profile',
              subtitle: 'View and edit your profile information',
              onTap: () => Navigator.pushNamed(context, '/driver/profile'),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: '📱',
              title: 'My QR Code',
              subtitle: 'Show this at fuel stations to get scanned',
              onTap: () => Navigator.pushNamed(context, '/driver/qr-code'),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: '📊',
              title: 'Boda Score',
              subtitle: 'Check your credit score and history',
              onTap: () => Navigator.pushNamed(context, '/driver/score'),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: '💰',
              title: 'My Loans',
              subtitle: 'Apply for and manage your loans',
              onTap: () => Navigator.pushNamed(context, '/driver/loans'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Mafuta (Lita)',
                    value: (_summary?.totalLiters ?? 0).toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Jumla (TSh)',
                    value: '${(_summary?.totalAmountTsh ?? 0).round()}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Matumizi ya Hivi Karibuni',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Hakuna matumizi bado',
                      style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_history.length.clamp(0, 5), (i) {
                final scan = _history[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      scan.stationName ?? 'Station',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${scan.liters.toStringAsFixed(1)}L · ${scan.scannedAt != null ? "${scan.scannedAt!.day}/${scan.scannedAt!.month} ${scan.scannedAt!.hour}:${scan.scannedAt!.minute.toString().padLeft(2, '0')}" : ""}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                    ),
                    trailing: Text(
                      'TSh ${scan.amountTsh.round()}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: AppTheme.gray),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.grayLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.gray,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}
