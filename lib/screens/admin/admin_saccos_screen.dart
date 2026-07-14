import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';
import '../sacco/sacco_home_screen.dart';

class AdminSaccosScreen extends StatefulWidget {
  const AdminSaccosScreen({super.key});

  @override
  State<AdminSaccosScreen> createState() => _AdminSaccosScreenState();
}

class _AdminSaccosScreenState extends State<AdminSaccosScreen> {
  final _api = ApiService();
  List<dynamic> _saccos = [];
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
        _loadSaccos();
      }
    });
  }

  Future<void> _loadSaccos() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/saccos');
      setState(() {
        _saccos = res['saccos'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindikana kupakia SACCOs: $e'), backgroundColor: AppTheme.red),
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
      onRefresh: _loadSaccos,
      child: _saccos.isEmpty
          ? Center(
              child: Text(
                'Hakuna SACCOs zilizosajiliwa',
                style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _saccos.length,
              itemBuilder: (ctx, idx) {
                final s = _saccos[idx];
                final name = s['name'] ?? '';
                final regNo = s['registration_number'] ?? '';
                final chairperson = s['chairperson'] ?? '';
                final phone = s['phone'] ?? '';
                final members = s['member_count'] ?? 0;
                final activeLoans = s['active_loans_count'] ?? 0;
                final collections = double.tryParse(s['total_collections_tsh']?.toString() ?? '0') ?? 0;
                final active = s['status'] == 'active';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SaccoHomeScreen(
                          saccoId: s['id']?.toString(),
                          saccoName: name,
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
                          Text('Reg No: $regNo', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _statColumn('Wanachama', '$members'),
                              _statColumn('Mikopo Inayoendelea', '$activeLoans'),
                              _statColumn('Makusanyo', 'TSh ${collections.toStringAsFixed(0)}'),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: AppTheme.gray),
                              const SizedBox(width: 6),
                              Text('Chairperson: $chairperson', style: TextStyle(fontSize: 13, color: AppTheme.navy)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: AppTheme.gray),
                              const SizedBox(width: 6),
                              Text('Simu: $phone', style: TextStyle(fontSize: 13, color: AppTheme.navy)),
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
