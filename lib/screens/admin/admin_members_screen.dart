import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _api = ApiService();
  List<dynamic> _drivers = [];
  List<dynamic> _filteredDrivers = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDrivers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/drivers');
      final list = res['drivers'] as List? ?? [];
      setState(() {
        _drivers = list;
        _filteredDrivers = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindikana kupakia wanachama: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterDrivers(String q) {
    setState(() {
      if (q.isEmpty) {
        _filteredDrivers = _drivers;
      } else {
        final query = q.toLowerCase();
        _filteredDrivers = _drivers.where((d) {
          final name = (d['full_name'] ?? '').toString().toLowerCase();
          final phone = (d['phone'] ?? '').toString().toLowerCase();
          final plate = (d['vehicle_plate'] ?? '').toString().toLowerCase();
          final chapgoId = (d['chapgo_id'] ?? '').toString().toLowerCase();
          return name.contains(query) || phone.contains(query) || plate.contains(query) || chapgoId.contains(query);
        }).toList();
      }
    });
  }

  void _showDriverDetails(dynamic d) {
    showDialog(
      context: context,
      builder: (ctx) {
        final created = d['created_at'] != null ? d['created_at'].toString().substring(0, 10) : '—';
        final sacco = d['sacco_name'] ?? 'Hana SACCO';
        final score = d['boda_score'] ?? 0;
        final tier = (d['boda_tier'] ?? 'unranked').toString().toUpperCase();

        return AlertDialog(
          title: Text(d['full_name'] ?? 'Driver Details', style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('ID ya Chapgo', d['chapgo_id'] ?? '—'),
                _detailRow('Namba ya Simu', d['phone'] ?? '—'),
                _detailRow('Namba ya Chombo', d['vehicle_plate'] ?? '—'),
                _detailRow('SACCO', sacco),
                _detailRow('Boda Score', '$score ($tier)'),
                _detailRow('Status ya Akaunti', d['status'] ?? 'active'),
                _detailRow('Amejiunga tarehe', created),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Funga'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.navy, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tafuta dereva, namba ya simu, plate...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterDrivers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: _filterDrivers,
            ),
          ),
          Expanded(
            child: _filteredDrivers.isEmpty
                ? const Center(
                    child: Text(
                      'Hakuna madereva waliopatikana',
                      style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDrivers.length,
                    itemBuilder: (ctx, idx) {
                      final d = _filteredDrivers[idx];
                      final name = d['full_name'] ?? '';
                      final plate = d['vehicle_plate'] ?? '';
                      final phone = d['phone'] ?? '';
                      final score = d['boda_score'] ?? 0;
                      final active = d['status'] == 'active';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: active ? 'Active' : 'Pending',
                                variant: active ? BadgeVariant.active : BadgeVariant.pending,
                              ),
                            ],
                          ),
                          subtitle: Text('$plate · $phone\nBoda Score: $score'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showDriverDetails(d),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
