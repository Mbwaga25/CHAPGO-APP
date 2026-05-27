import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/scan.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class StationHomeScreen extends StatefulWidget {
  const StationHomeScreen({super.key});

  @override
  State<StationHomeScreen> createState() => _StationHomeScreenState();
}

class _StationHomeScreenState extends State<StationHomeScreen> {
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
      final summaryData = await _api.get('/station/daily-summary');
      final historyData = await _api.get('/scans/station-history');
      setState(() {
        _summary = DailySummary.fromJson(summaryData);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chapgo Station', style: TextStyle(fontSize: 16)),
            Text(
              user?.stationName ?? 'Station',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.goldLight,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Scans leo',
                          value: '${_summary?.scanCount ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Lita',
                          value: (_summary?.totalLiters ?? 0).toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Jumla ya mauzo leo',
                    value: 'TSh ${(_summary?.totalAmountTsh ?? 0).round()}',
                    fullWidth: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/station/scan'),
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: const Text('Scan Gari'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: AppTheme.white,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scans za hivi karibuni',
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
                            'Hakuna scans bado leo',
                            style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_history.length.clamp(0, 10), (i) {
                      final scan = _history[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            scan.driverName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${scan.liters.toStringAsFixed(1)}L · ${scan.vehiclePlate ?? ''}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                          ),
                          trailing: Text(
                            'TSh ${scan.amountTsh.round()}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chaguo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🏠', style: TextStyle(fontSize: 24)),
                title: const Text('Nyumbani'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Text('📷', style: TextStyle(fontSize: 24)),
                title: const Text('Scan Mpya'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/station/scan');
                },
              ),
              ListTile(
                leading: const Text('🔄', style: TextStyle(fontSize: 24)),
                title: const Text('Sasisha Takwimu'),
                onTap: () {
                  Navigator.pop(ctx);
                  _loadData();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Text('🚪', style: TextStyle(fontSize: 24)),
                title: const Text('Ondoka'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                  }
                },
              ),
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
  final bool fullWidth;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(fullWidth ? 20 : 16),
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
              style: TextStyle(
                fontSize: fullWidth ? 24 : 22,
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
