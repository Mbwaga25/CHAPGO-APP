import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'overview_screen.dart';
import 'admin_members_screen.dart';
import 'admin_saccos_screen.dart';
import 'admin_stations_screen.dart';
import 'admin_loans_screen.dart';
import 'safety_screen.dart';
import 'admin_escalations_screen.dart';
import 'campaigns_screen.dart';
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
    _ScreenInfo('Saccos', 'screenSaccos', Icons.business),
    _ScreenInfo('Petrol Stations', 'screenStations', Icons.local_gas_station),
    _ScreenInfo('Loans', 'screenLoans', Icons.monetization_on),
    _ScreenInfo('Ripoti Wizi', 'screenSafety', Icons.shield),
    _ScreenInfo('Escalations', 'screenEscalations', Icons.warning),
    _ScreenInfo('Campaigns', 'screenCampaigns', Icons.campaign),
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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_screens[_selectedIndex].title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text(
              'Admin Portal',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
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
          const AdminMembersScreen(),
          const AdminSaccosScreen(),
          const AdminStationsScreen(),
          const AdminLoansScreen(),
          const SafetyScreen(),
          const AdminEscalationsScreen(),
          const CampaignsScreen(),
          const OwnershipScreen(),
          const TitheScreen(),
          const ReportsScreen(),
          const AuditScreen(),
        ],
      ),
      bottomNavigationBar: _selectedIndex < 5 ? _buildBottomNav() : null,
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _adminNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
              _adminNavItem(1, Icons.people_outline, Icons.people, 'Members'),
              _adminNavItem(2, Icons.business_outlined, Icons.business, 'Saccos'),
              _adminNavItem(3, Icons.local_gas_station_outlined, Icons.local_gas_station, 'Stations'),
              _adminNavItem(4, Icons.monetization_on_outlined, Icons.monetization_on, 'Loans'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.navy.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? AppTheme.navy : AppTheme.grayLight, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.navy : AppTheme.grayLight,
              ),
            ),
          ],
        ),
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
              // ─── Profile header ───────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.gold, AppTheme.goldDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          user?.initials ?? 'A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Admin',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              (user?.role ?? 'admin').toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.goldLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Nav items ────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: user?.userRole == UserRole.saccoAdmin
                      ? [
                          const _NavSection(label: 'Operations'),
                          _NavItem(icon: _screens[0].icon, label: _screens[0].title,
                              isSelected: _selectedIndex == 0, onTap: () => _onSelect(0)),
                          _NavItem(icon: _screens[1].icon, label: _screens[1].title,
                              isSelected: _selectedIndex == 1, onTap: () => _onSelect(1)),
                          _NavItem(icon: _screens[4].icon, label: _screens[4].title,
                              isSelected: _selectedIndex == 4, onTap: () => _onSelect(4)),
                        ]
                      : [
                          const _NavSection(label: 'Operations'),
                          ..._screens.take(8).toList().asMap().entries.map((e) =>
                            _NavItem(
                              icon: e.value.icon,
                              label: e.value.title,
                              isSelected: _selectedIndex == e.key,
                              onTap: () => _onSelect(e.key),
                            ),
                          ),
                          const _NavSection(label: 'Covenant'),
                          ..._screens.skip(8).take(2).toList().asMap().entries.map((e) =>
                            _NavItem(
                              icon: e.value.icon,
                              label: e.value.title,
                              isSelected: _selectedIndex == e.key + 8,
                              onTap: () => _onSelect(e.key + 8),
                            ),
                          ),
                          const _NavSection(label: 'Reporting'),
                          ..._screens.skip(10).toList().asMap().entries.map((e) =>
                            _NavItem(
                              icon: e.value.icon,
                              label: e.value.title,
                              isSelected: _selectedIndex == e.key + 10,
                              onTap: () => _onSelect(e.key + 10),
                            ),
                          ),
                        ],
                ),
              ),

              // ─── Footer ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('v1.0 · Pilot',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, color: AppTheme.red, size: 18),
                            SizedBox(width: 8),
                            Text('Sign Out', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.gold.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppTheme.gold.withValues(alpha: 0.3)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.gold.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isSelected ? AppTheme.gold : Colors.white60, size: 18),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          onTap: onTap,
        ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.construction, size: 48, color: AppTheme.grayLight),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.gray)),
          ],
        ),
      ),
    );
  }
}
