import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'overview_screen.dart';
import 'safety_screen.dart';
import 'ownership_screen.dart';
import 'tithe_screen.dart';
import 'reports_screen.dart';
import 'audit_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final _screens = [
    _ScreenInfo('Overview', 'screenOverview', Icons.dashboard),
    _ScreenInfo('Members', 'screenMembers', Icons.people),
    _ScreenInfo('Loans', 'screenLoans', Icons.monetization_on),
    _ScreenInfo('Ripoti Wizi', 'screenSafety', Icons.shield),
    _ScreenInfo('Escalations', 'screenEscalations', Icons.warning),
    _ScreenInfo('Member Ownership', 'screenOwnership', Icons.article),
    _ScreenInfo('Tithe Ledger', 'screenTithe', Icons.handshake),
    _ScreenInfo('RC Quarterly', 'screenReports', Icons.description),
    _ScreenInfo('Audit Log', 'screenAudit', Icons.search),
  ];

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screens[_selectedIndex].title),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const OverviewScreen(),
          const PlaceholderScreen('Members', 'Member listing endpoint pending — Phase 2 enhancement'),
          const PlaceholderScreen('Loans', 'Loan admin listing pending — Phase 2 enhancement'),
          const SafetyScreen(),
          const PlaceholderScreen('Escalations', 'Escalation listing endpoint pending — Phase 2 enhancement. Ops Lead receives WhatsApp alerts in realtime.'),
          const OwnershipScreen(),
          const TitheScreen(),
          const ReportsScreen(),
          const AuditScreen(),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Drawer(
      child: Container(
        color: AppTheme.navy,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.gold,
                      child: Text(
                        user?.initials ?? 'A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Admin',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user?.role ?? 'admin',
                          style: const TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.navyLight),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _NavSection(label: 'Operations'),
                    ..._screens.take(5).toList().asMap().entries.map((e) =>
                      _NavItem(
                        icon: e.value.icon,
                        label: e.value.title,
                        isSelected: _selectedIndex == e.key,
                        onTap: () => _onSelect(e.key),
                      ),
                    ),
                    _NavSection(label: 'Covenant'),
                    ..._screens.skip(5).take(2).toList().asMap().entries.map((e) =>
                      _NavItem(
                        icon: e.value.icon,
                        label: e.value.title,
                        isSelected: _selectedIndex == e.key + 5,
                        onTap: () => _onSelect(e.key + 5),
                      ),
                    ),
                    _NavSection(label: 'Reporting'),
                    ..._screens.skip(7).toList().asMap().entries.map((e) =>
                      _NavItem(
                        icon: e.value.icon,
                        label: e.value.title,
                        isSelected: _selectedIndex == e.key + 7,
                        onTap: () => _onSelect(e.key + 7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('v1.0 · Pilot', style: TextStyle(color: AppTheme.grayLight, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppTheme.goldLight, size: 18),
                      label: const Text('Sign Out', style: TextStyle(color: AppTheme.goldLight)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenInfo {
  final String title;
  final String route;
  final IconData icon;
  _ScreenInfo(this.title, this.route, this.icon);
}

class _NavSection extends StatelessWidget {
  final String label;
  const _NavSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.grayLight,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.gold.withValues(alpha: 0.15) : null,
        border: isSelected
            ? const Border(left: BorderSide(color: AppTheme.gold, width: 3))
            : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.white, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.white : AppTheme.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  const PlaceholderScreen(this.title, this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 48, color: AppTheme.grayLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }
}
