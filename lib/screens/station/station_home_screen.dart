import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/scan.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'operators_screen.dart';

class StationHomeScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;
  const StationHomeScreen({super.key, this.stationId, this.stationName});

  @override
  State<StationHomeScreen> createState() => _StationHomeScreenState();
}

class _StationHomeScreenState extends State<StationHomeScreen> {
  final _api = ApiService();
  DailySummary? _summary;
  List<Scan> _history = [];
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _api.setToken(user.token);
    if (widget.stationId != null) {
      _api.customStationId = widget.stationId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final summaryData = await _api.get('/station/daily-summary');
      final historyData = await _api.get('/scans/station-history');
      setState(() {
        _summary = DailySummary.fromJson(summaryData);
        _history = (historyData['scans'] as List?)?.map((s) => Scan.fromJson(s)).toList() ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final stationName = widget.stationName ?? user?.stationName ?? 'Station';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentIndex == 2 ? 'Wafanyakazi' : 'Chapgo Station',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              stationName,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65), letterSpacing: 0.5),
            ),
          ],
        ),
        leading: widget.stationId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      drawer: widget.stationId != null
          ? null
          : Drawer(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 24,
                      bottom: 24,
                      left: 20,
                      right: 20,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.navy, Color(0xFF1E3A5F)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.local_gas_station, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.fullName ?? 'Operator',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('${user?.phone ?? ''} · $stationName',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _drawerItem(context, Icons.dashboard, 'Nyumbani', () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 0);
                        }),
                        const Divider(height: 1),
                        _drawerItem(context, Icons.qr_code_scanner, 'Scan Gari', () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/station/scan');
                        }),
                        const Divider(height: 1),
                        _drawerItem(context, Icons.people, 'Wafanyakazi (Operators)', () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 2);
                        }),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: AppTheme.red, size: 20),
                    ),
                    title: const Text('Ondoka', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          const SizedBox.shrink(),
          const OperatorsScreen(isEmbedded: true),
        ],
      ),
      bottomNavigationBar: widget.stationId != null
          ? null
          : _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: [
          BoxShadow(color: AppTheme.navy.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Nyumbani'),
              _scanNavItem(),
              _navItem(2, Icons.people_outline, Icons.people, 'Wafanyakazi'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.navy.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? AppTheme.navy : AppTheme.grayLight, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppTheme.navy : AppTheme.grayLight,
                )),
          ],
        ),
      ),
    );
  }

  Widget _scanNavItem() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/station/scan'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.gold, AppTheme.goldDark],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppTheme.gold.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Scan Gari',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // ─── Gradient stats header ────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.navy, Color(0xFF1E3A5F)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _headerStat(
                              'Scans Leo',
                              '${_summary?.scanCount ?? 0}',
                              Icons.qr_code_scanner,
                              AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _headerStat(
                              'Lita',
                              '${(_summary?.totalLiters ?? 0).toStringAsFixed(1)} L',
                              Icons.local_gas_station,
                              AppTheme.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.attach_money, color: AppTheme.green, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jumla ya Mauzo Leo',
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  'TSh ${(_summary?.totalAmountTsh ?? 0).round()}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Scan button ────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/station/scan'),
                      icon: const Icon(Icons.qr_code_scanner, size: 22),
                      label: const Text('Scan Gari',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),

                // ─── Recent scans ────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Scans za Hivi Karibuni', style: AppTheme.headingSmall),
                ),

                if (_history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 36, color: AppTheme.grayLight),
                            SizedBox(height: 10),
                            Text('Hakuna scans bado leo',
                                style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(_history.length.clamp(0, 10), (i) {
                        final scan = _history[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.motorcycle, color: AppTheme.teal, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(scan.driverName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text('${scan.liters.toStringAsFixed(1)}L · ${scan.vehiclePlate ?? ""}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                                  ],
                                ),
                              ),
                              Text('TSh ${scan.amountTsh.round()}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.navy.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.navy, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
