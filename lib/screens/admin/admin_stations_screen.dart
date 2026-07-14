import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';
import '../station/station_home_screen.dart';

class AdminStationsScreen extends StatefulWidget {
  const AdminStationsScreen({super.key});

  @override
  State<AdminStationsScreen> createState() => _AdminStationsScreenState();
}

class _AdminStationsScreenState extends State<AdminStationsScreen> {
  final _api = ApiService();
  List<dynamic> _stations = [];
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
        _loadStations();
      }
    });
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/stations');
      setState(() {
        _stations = res['stations'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindikana kupakia vituo: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStations,
      child: _stations.isEmpty
          ? Center(
              child: Text(
                'Hakuna vituo vya mafuta vilivyosajiliwa',
                style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stations.length,
              itemBuilder: (ctx, idx) {
                final s = _stations[idx];
                final name = s['name'] ?? '';
                final district = s['district'] ?? '';
                final ward = s['ward'] ?? '';
                final scans = s['scan_count'] ?? 0;
                final liters = double.tryParse(s['total_liters']?.toString() ?? '0') ?? 0;
                final totalAmount = double.tryParse(s['total_amount_tsh']?.toString() ?? '0') ?? 0;
                final active = s['partnership_status'] == 'active';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StationHomeScreen(
                          stationId: s['id']?.toString(),
                          stationName: name,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
                              StatusBadge(
                                label: active ? 'Active' : 'Inactive',
                                variant: active ? BadgeVariant.active : BadgeVariant.pending,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: AppTheme.gray),
                              const SizedBox(width: 4),
                              Text('$district, $ward', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _statColumn('Scans zote', '$scans'),
                              _statColumn('Lita', '${liters.toStringAsFixed(1)} L'),
                              _statColumn('Jumla Mauzo', 'TSh ${totalAmount.toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.gray, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, color: AppTheme.navy, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
