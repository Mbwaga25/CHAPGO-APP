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

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();

  // RC Quarterly Tab State
  List<QuarterlyReport> _quarterlyReports = [];
  bool _loadingQuarterly = true;

  // Boda Score Tab State
  List<dynamic> _drivers = [];
  bool _loadingDrivers = true;
  dynamic _selectedDriver;
  dynamic _currentScoreDetails;
  List<dynamic> _scoreHistory = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    
    _loadQuarterlyData();
    _loadDriversData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuarterlyData() async {
    if (mounted) {
      setState(() => _loadingQuarterly = true);
    }
    try {
      final r = await _api.get('/reports/rc-quarterly');
      if (!mounted) return;
      setState(() {
        _quarterlyReports = (r['reports'] as List?)?.map((x) => QuarterlyReport.fromJson(x)).toList() ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load quarterly reports: $e'), backgroundColor: AppTheme.red));
      }
    } finally {
      if (mounted) setState(() => _loadingQuarterly = false);
    }
  }

  Future<void> _loadDriversData() async {
    if (mounted) {
      setState(() => _loadingDrivers = true);
    }
    try {
      final res = await _api.get('/admin/drivers');
      if (!mounted) return;
      setState(() {
        _drivers = res['drivers'] as List? ?? [];
      });
    } catch (e) {
      debugPrint('Error loading drivers: $e');
    } finally {
      if (mounted) setState(() => _loadingDrivers = false);
    }
  }

  Future<void> _selectDriver(dynamic driver) async {
    if (mounted) {
      setState(() {
        _selectedDriver = driver;
        _loadingHistory = true;
        _currentScoreDetails = null;
        _scoreHistory = [];
      });
    }

    try {
      // 1. Live recalculate score
      final scoreRes = await _api.post('/scores/admin/recalculate/${driver['id']}');
      // 2. Fetch history
      final historyRes = await _api.get('/scores/admin/history/${driver['id']}');

      if (!mounted) return;
      setState(() {
        _currentScoreDetails = scoreRes;
        _scoreHistory = historyRes is List ? historyRes : [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch score details: $e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
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
              try {
                await _api.post('/reports/rc-quarterly/generate', body: {'quarter': q, 'year': y});
                _loadQuarterlyData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.red));
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _markDelivered(String id) async {
    try {
      await _api.post('/reports/rc-quarterly/$id/delivered');
      _loadQuarterlyData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.red));
    }
  }

  void _showDriverSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        List<dynamic> localFiltered = _drivers;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Select Boda Driver', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 420,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Tafuta dereva, namba ya simu, plate...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        setLocalState(() {
                          if (val.isEmpty) {
                            localFiltered = _drivers;
                          } else {
                            final q = val.toLowerCase();
                            localFiltered = _drivers.where((d) {
                              final name = (d['full_name'] ?? '').toString().toLowerCase();
                              final phone = (d['phone'] ?? '').toString().toLowerCase();
                              final plate = (d['vehicle_plate'] ?? '').toString().toLowerCase();
                              final chapgo = (d['chapgo_id'] ?? '').toString().toLowerCase();
                              return name.contains(q) || phone.contains(q) || plate.contains(q) || chapgo.contains(q);
                            }).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: localFiltered.isEmpty
                          ? const Center(child: Text('No drivers found', style: TextStyle(fontStyle: FontStyle.italic)))
                          : ListView.builder(
                              itemCount: localFiltered.length,
                              itemBuilder: (c, idx) {
                                final d = localFiltered[idx];
                                return ListTile(
                                  title: Text(d['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${d['chapgo_id']} · ${d['vehicle_plate']}'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _selectDriver(d);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return Colors.teal;
      case 'gold':
        return AppTheme.gold;
      case 'silver':
        return Colors.blueGrey;
      case 'bronze':
        return Colors.deepOrange;
      default:
        return AppTheme.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: AppBar(
          title: const Text('Admin Reports'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'RC Quarterly'),
              Tab(text: 'Boda Score Audit'),
            ],
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRCQuarterlyTab(),
          _buildBodaScoreAuditTab(),
        ],
      ),
    );
  }

  Widget _buildRCQuarterlyTab() {
    if (_loadingQuarterly) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadQuarterlyData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RC Quarterly Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text('Quarterly reports delivered to RC Dar es Salaam office', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Generated Reports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
              ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Generate New Report', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_quarterlyReports.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No reports generated yet', style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)))))
          else
            ..._quarterlyReports.map((r) => Card(
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
                              Text('${r.reportYear}', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${r.periodStart} — ${r.periodEnd}', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
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
                            child: Text('Mark Delivered', style: TextStyle(fontSize: 11, color: AppTheme.green)),
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

  Widget _buildBodaScoreAuditTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.border, width: 1),
          ),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Boda Score Audit Tool',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a driver to inspect live calculation parameters, breakdown scores, and history audit trails.',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray),
                ),
                const SizedBox(height: 16),
                _loadingDrivers
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _showDriverSearchDialog,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: Text(
                          _selectedDriver == null ? 'Select Driver' : 'Selected: ${_selectedDriver['full_name']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedDriver == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.query_stats_outlined, size: 72, color: AppTheme.grayLight),
                  const SizedBox(height: 12),
                  Text(
                    'No driver selected',
                    style: TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic, fontSize: 15),
                  ),
                ],
              ),
            ),
          )
        else if (_loadingHistory)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          _buildScoreSummaryCard(),
          const SizedBox(height: 16),
          _buildBreakdownCard(),
          const SizedBox(height: 16),
          _buildAuditHistoryCard(),
        ]
      ],
    );
  }

  Widget _buildScoreSummaryCard() {
    if (_currentScoreDetails == null) return const SizedBox();

    final score = _currentScoreDetails['score'] ?? 0;
    final tier = (_currentScoreDetails['tier'] ?? 'NEW').toString().toUpperCase();
    final thinFile = _currentScoreDetails['thinFile'] ?? false;
    final activeDays = _currentScoreDetails['days_active'] ?? 0;
    final totalLiters = _currentScoreDetails['total_liters'] ?? 0.0;
    final totalSpent = _currentScoreDetails['total_spent_tsh'] ?? 0.0;
    final totalScans = _currentScoreDetails['total_scans'] ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _getTierColor(tier).withOpacity(0.12),
                  child: Text(
                    '$score',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getTierColor(tier)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDriver['full_name'] ?? 'Rider Profile',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTierColor(tier).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tier,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getTierColor(tier),
                              ),
                            ),
                          ),
                          if (thinFile) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'THIN FILE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryStat('Active Days', '$activeDays'),
                _summaryStat('Total Scans', '$totalScans'),
                _summaryStat('Total Liters', '${totalLiters.toStringAsFixed(1)}L'),
                _summaryStat('Total Spent', 'TSh ${NumberFormatCompact().format(totalSpent)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.gray)),
      ],
    );
  }

  Widget _buildBreakdownCard() {
    if (_currentScoreDetails == null) return const SizedBox();
    final b = _currentScoreDetails['breakdown'] ?? {};

    final inc = b['income'] ?? 0;
    final att = b['attendance'] ?? 0;
    final hrs = b['hours'] ?? 0;
    final eff = b['efficiency'] ?? 0;
    final sac = b['sacco'] ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score Points Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
            const SizedBox(height: 16),
            _breakdownRow('Income Consistency', inc, 350),
            _breakdownRow('Working Attendance', att, 250),
            _breakdownRow('Hours Discipline', hrs, 150),
            _breakdownRow('Fuel Efficiency', eff, 150),
            _breakdownRow('SACCO Participation', sac, 100),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String name, int score, int max) {
    final pct = score / max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$score / $max points', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditHistoryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculation History & Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
            const SizedBox(height: 12),
            if (_scoreHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No historical score calculations recorded yet.', style: TextStyle(fontStyle: FontStyle.italic))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _scoreHistory.length,
                itemBuilder: (context, idx) {
                  final h = _scoreHistory[idx];
                  final score = h['score'] ?? 0;
                  final tier = (h['tier'] ?? 'NEW').toString().toUpperCase();
                  final date = h['calculated_at'] != null ? h['calculated_at'].toString().substring(0, 10) : '—';
                  final time = h['calculated_at'] != null ? h['calculated_at'].toString().substring(11, 16) : '';
                  final flags = h['integrity_flags'] as List? ?? [];
                  
                  final inc = h['income_points'] ?? 0;
                  final att = h['attendance_points'] ?? 0;
                  final hrs = h['hours_points'] ?? 0;
                  final eff = h['efficiency_points'] ?? 0;
                  final sac = h['sacco_points'] ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.border, width: idx == _scoreHistory.length - 1 ? 0 : 1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$score',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _getTierColor(tier)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tier,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _getTierColor(tier)),
                                ),
                              ],
                            ),
                            Text('$date $time', style: TextStyle(color: AppTheme.gray, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Telemetry: ${h['total_liters']}L · ${h['total_scans']} scans · ${h['days_active']} days active',
                          style: TextStyle(fontSize: 11, color: AppTheme.gray),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Breakdown: Inc: $inc, Att: $att, Hrs: $hrs, Eff: $eff, Sacco: $sac',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        if (flags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: flags.map<Widget>((f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                f.toString().toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(color: AppTheme.red, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            )).toList(),
                          )
                        ]
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Simple Helper class to format compact currency strings
class NumberFormatCompact {
  String format(dynamic number) {
    final num = double.tryParse(number.toString()) ?? 0.0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    }
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toStringAsFixed(0);
  }
}
