import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/cashflow_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/theme_toggle_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'driver_widgets.dart';
import 'driver_delivery_screen.dart';

String fmtTsh(num v) {
  final n = v.round();
  if (n >= 1000000) return 'TZS ${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return 'TZS ${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  return 'TZS $n';
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  final _api = ApiService();
  bool _loading = true;
  bool _dataLoadedOnce = false;
  bool _tabHandled = false;

  // backend data
  double _score = 0;
  String _tier = 'unranked';
  int _daysActive = 0;
  int _totalScans = 0;
  Map<String, dynamic>? _eligibility;
  Map<String, dynamic>? _profile;
  List<dynamic> _scans = [];
  Map<String, dynamic> _scanTotals = {};
  int _unread = 0;
  Map<String, dynamic>? _credit;
  bool _creditLoading = false;

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  bool _cashflowApiSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
      // Only wire the cashflow API once. didChangeDependencies fires on every
      // CashflowProvider notifyListeners (the My Money tab watches it), so
      // calling setApi()/fetchAndSync() here every time creates an infinite
      // request loop against /driver/cashflow.
      if (!_cashflowApiSet) {
        _cashflowApiSet = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<CashflowProvider>().setApi(_api);
        });
      }
    }
    if (!_tabHandled) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final tab = args?['tab'] as int?;
      if (tab != null) _currentIndex = tab;
      _tabHandled = true;
    }
    if (!_dataLoadedOnce) {
      _dataLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final score = await _api.get('/scores/me');
      if (mounted) {
        _score = _num(score['score']);
        _tier = score['tier'] as String? ?? 'unranked';
        _daysActive = _num(score['days_active']).round();
        _totalScans = _num(score['total_scans']).round();
        _eligibility = score['loan_eligibility'] as Map<String, dynamic>?;
      }
    } catch (e) { debugPrint('score: $e'); }
    try {
      _profile = await _api.get('/driver/profile') as Map<String, dynamic>?;
    } catch (e) { debugPrint('profile: $e'); }
    try {
      final hist = await _api.get('/scans/my-history?days=30');
      _scans = hist['scans'] as List? ?? [];
      _scanTotals = (hist['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    } catch (e) { debugPrint('scans: $e'); }
    try {
      final notif = await _api.get('/driver/notifications');
      final list = notif['notifications'] as List? ?? [];
      _unread = list.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
    } catch (e) { debugPrint('notif: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final user = context.watch<AuthProvider>().user;
    context.watch<ThemeProvider>(); // rebuild + recolor on theme toggle
    return Scaffold(
      backgroundColor: DriverDark.dark,
      appBar: _appBar(lang),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: DriverDark.gold))
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(lang),
                _buildHistoryTab(lang),   // Scan (Today)
                _buildMoneyTab(lang),
                _buildCreditTab(lang),    // Credit (AI)
                const DriverDeliveryView(),
                _buildProfileTab(lang),
              ],
            ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                final phone = _profile?['phone'] as String? ?? user?.phone ?? '';
                _showQrCodeBottomSheet(lang, phone);
              },
              backgroundColor: DriverDark.gold,
              foregroundColor: DriverDark.dark,
              child: const Icon(Icons.qr_code_2),
            )
          : null,
      bottomNavigationBar: _bottomNav(lang),
    );
  }

  PreferredSizeWidget _appBar(LanguageProvider lang) {
    return AppBar(
      backgroundColor: DriverDark.dark,
      foregroundColor: DriverDark.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(colors: [DriverDark.green, DriverDark.gold]),
            ),
            child: Text('C', style: TextStyle(fontWeight: FontWeight.w800, color: DriverDark.dark)),
          ),
          const SizedBox(width: 10),
          Text('Chap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: DriverDark.white)),
          Text('go', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: DriverDark.gold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => lang.setLocale(lang.locale == 'en' ? 'sw' : 'en'),
          child: Text(lang.locale == 'en' ? 'SW' : 'EN',
              style: TextStyle(color: DriverDark.greyLight, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const ThemeToggleButton(),
        RingingBell(
          count: _unread,
          onTap: () => Navigator.pushNamed(context, '/driver/notifications').then((_) => _loadData(silent: true)),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _bottomNav(LanguageProvider lang) {
    final items = [
      [Icons.home_filled, lang.translate('nav_home')],
      [Icons.qr_code_scanner, lang.translate('nav_scan')],
      [Icons.account_balance_wallet, lang.translate('nav_money')],
      [Icons.credit_score, lang.translate('nav_credit')],
      [Icons.local_shipping, lang.translate('deliver')],
      [Icons.person, lang.translate('nav_profile')],
    ];
    return Container(
      decoration: BoxDecoration(
        color: DriverDark.navy,
        border: Border(top: BorderSide(color: DriverDark.cardBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i][0] as IconData,
                            size: 22, color: active ? DriverDark.gold : DriverDark.grey),
                        const SizedBox(height: 3),
                        Text(items[i][1] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? DriverDark.gold : DriverDark.grey)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB 0 — HOME
  // ════════════════════════════════════════════════════════
  Widget _buildHomeTab(LanguageProvider lang) {
    final tierColor = DriverDark.tierColor(_tier);
    final litres = _num(_scanTotals['total_liters']);
    final spent = _num(_scanTotals['total_amount_tsh']);
    final status = (_profile?['status'] as String?) ?? 'active';
    final isActive = status == 'active';
    final saccoName = _profile?['sacco_name'] as String?;
    final saccoBalance = _num(_profile?['sacco_balance_tsh']);
    final prequalPct = (_daysActive / 90).clamp(0.0, 1.0);
    final eligible = _daysActive >= 90;

    return RefreshIndicator(
      color: DriverDark.gold,
      backgroundColor: DriverDark.navy,
      onRefresh: () => _loadData(silent: true),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Score ring + info
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/driver/score').then((_) => _loadData(silent: true)),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  DScoreRing(
                    value: _score / 1000,
                    centerText: '${_score.round()}',
                    maxText: '/ 1000',
                    color: tierColor,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.translate('boda_score'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DriverDark.white)),
                        const SizedBox(height: 6),
                        DBadge(text: '${_tier.toUpperCase()} TIER', color: tierColor),
                        const SizedBox(height: 8),
                        Text(
                          '$_daysActive ${lang.translate('days_active_short').toLowerCase()} · $_totalScans ${lang.translate('scan_count_label').toLowerCase()}'
                          '${saccoName != null ? '\nSACCO: $saccoName' : ''}',
                          style: TextStyle(fontSize: 11, color: DriverDark.grey, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                DStatGrid(cards: [
                  DStatCard(value: '$_daysActive', label: lang.translate('days_active_short'), valueColor: DriverDark.greenLight),
                  DStatCard(value: '$_totalScans', label: lang.translate('scan_count_label'), valueColor: DriverDark.gold),
                  DStatCard(value: '${litres.toStringAsFixed(0)}L', label: lang.translate('litres_30d')),
                  DStatCard(value: fmtTsh(spent), label: lang.translate('fuel_spent_30d'), valueColor: DriverDark.greenLight),
                ]),

                // Status
                DSectionHead(title: lang.translate('your_status')),
                DCard(
                  child: DListItem(
                    emoji: isActive ? '✅' : '⏳',
                    emojiBg: (isActive ? DriverDark.green : DriverDark.gold).withValues(alpha: 0.15),
                    title: lang.translate('registration_complete'),
                    meta: _profile?['chapgo_id'] as String? ?? '',
                    trailing: DBadge(
                      text: isActive ? lang.translate('account_active') : lang.translate('account_pending'),
                      color: isActive ? DriverDark.greenLight : DriverDark.gold,
                    ),
                  ),
                ),

                // Loan pre-qualification
                DSectionHead(title: lang.translate('financial_services')),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/driver/loans').then((_) => _loadData(silent: true)),
                  child: DCard(
                    borderColor: DriverDark.gold.withValues(alpha: 0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38, height: 38, alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: DriverDark.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Text('🏦', style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lang.translate('loan_prequal'),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DriverDark.white)),
                                  const SizedBox(height: 2),
                                  Text(
                                    eligible
                                        ? lang.translate('eligible_now')
                                        : '${90 - _daysActive} ${lang.translate('days_until_eligible')}',
                                    style: TextStyle(fontSize: 12, color: DriverDark.grey),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: DriverDark.grey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DProgressBar(value: prequalPct, color: eligible ? DriverDark.greenLight : DriverDark.gold),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$_daysActive / 90 ${lang.translate('days_active_short').toLowerCase()}',
                                style: TextStyle(fontSize: 11, color: DriverDark.grey)),
                            Text('${(prequalPct * 100).round()}% ${lang.translate('complete_label')}',
                                style: TextStyle(fontSize: 11, color: DriverDark.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent scans
                DSectionHead(
                  title: lang.translate('recent_scans'),
                  actionLabel: lang.translate('see_all'),
                  onAction: () => setState(() => _currentIndex = 1),
                ),
                DCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _scans.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(lang.translate('no_scans_yet'),
                                style: TextStyle(color: DriverDark.grey, fontStyle: FontStyle.italic)),
                          ),
                        )
                      : Column(
                          children: _scans.take(3).map((s) {
                            return DListItem(
                              emoji: '⛽',
                              emojiBg: DriverDark.green.withValues(alpha: 0.12),
                              title: s['station_name'] as String? ?? 'Station',
                              meta: _fmtDate(s['scanned_at']),
                              trailing: DTrailingValue(
                                amount: '${_num(s['liters']).toStringAsFixed(1)}L',
                                unit: fmtTsh(_num(s['amount_tsh'])),
                              ),
                            );
                          }).toList(),
                        ),
                ),

                // SACCO
                if (saccoName != null) ...[
                  const SizedBox(height: 16),
                  DCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38, height: 38, alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: DriverDark.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Text('🏛️', style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(saccoName,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DriverDark.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _saccoMini(fmtTsh(saccoBalance), lang.translate('savings_balance'), DriverDark.white)),
                            const SizedBox(width: 10),
                            Expanded(child: _saccoMini(lang.translate('current'), lang.translate('dues_status'), DriverDark.greenLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _saccoMini(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: DriverDark.card, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: DriverDark.grey)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB 1 — MY MONEY
  // ════════════════════════════════════════════════════════
  Widget _buildMoneyTab(LanguageProvider lang) {
    final cashflow = context.watch<CashflowProvider>();
    final txs = cashflow.transactions;
    final income = txs.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final expense = txs.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final surplus = income - expense;

    // group expenses by category
    final Map<String, double> byCat = {};
    for (final t in txs.where((t) => t.type == 'expense')) {
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
    }
    final cats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      color: DriverDark.gold,
      backgroundColor: DriverDark.navy,
      onRefresh: () => _loadData(silent: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(lang.translate('nav_money'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: DriverDark.white)),
          const SizedBox(height: 4),
          Text(lang.translate('my_money_subtitle'),
              style: TextStyle(fontSize: 13, color: DriverDark.grey)),
          const SizedBox(height: 16),

          // Cashflow summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [DriverDark.green.withValues(alpha: 0.10), DriverDark.gold.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverDark.green.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('cashflow_30d'),
                        style: TextStyle(fontSize: 12, color: DriverDark.grey, letterSpacing: 1)),
                    DBadge(text: surplus >= 0 ? 'Healthy' : 'Watch', color: surplus >= 0 ? DriverDark.greenLight : DriverDark.red),
                  ],
                ),
                const SizedBox(height: 16),
                _barRow(lang.translate('est_income'), income, income, DriverDark.greenLight),
                const SizedBox(height: 12),
                _barRow(lang.translate('reported_spending'), expense, income == 0 ? expense : income, DriverDark.gold),
                const SizedBox(height: 12),
                const DRowDivider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('estimated_surplus'),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DriverDark.white)),
                    Text(fmtTsh(surplus),
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: surplus >= 0 ? DriverDark.greenLight : DriverDark.red)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Why track
          DCard(
            borderColor: DriverDark.gold.withValues(alpha: 0.2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.translate('why_track'),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DriverDark.white)),
                      const SizedBox(height: 4),
                      Text(lang.translate('why_track_desc'),
                          style: TextStyle(fontSize: 12, color: DriverDark.greyLight, height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Spending categories
          DSectionHead(
            title: lang.translate('this_month_spending'),
            actionLabel: '+ ${lang.translate('add')}',
            onAction: () => _showAddExpense(lang, cashflow),
          ),
          DCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: cats.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(lang.translate('no_spending_yet'),
                          style: TextStyle(color: DriverDark.grey, fontStyle: FontStyle.italic)),
                    ),
                  )
                : Column(
                    children: cats.map((e) {
                      return DListItem(
                        emoji: _catEmoji(e.key),
                        emojiBg: DriverDark.red.withValues(alpha: 0.10),
                        title: lang.translate(e.key),
                        trailing: DTrailingValue(amount: fmtTsh(e.value), amountColor: DriverDark.red),
                      );
                    }).toList(),
                  ),
          ),

          // Credit profile
          DSectionHead(
            title: lang.translate('credit_profile'),
            trailing: DBadge(text: 'For Bank Review', color: DriverDark.gold),
          ),
          DCard(
            borderColor: DriverDark.green.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.translate('what_bank_sees'),
                    style: TextStyle(fontSize: 12, color: DriverDark.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                _creditRow(lang.translate('total_income'), fmtTsh(income), DriverDark.greenLight),
                _creditRow(lang.translate('total_expenses'), fmtTsh(expense), DriverDark.white),
                _creditRow(lang.translate('estimated_surplus'), fmtTsh(surplus), DriverDark.gold),
                if (_eligibility != null)
                  _creditRow(lang.translate('credit_limit'),
                      '${fmtTsh(_num(_eligibility!['min']))} — ${fmtTsh(_num(_eligibility!['max']))}', DriverDark.gold,
                      last: true),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _barRow(String label, double value, double max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color)),
            Text(fmtTsh(value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        DProgressBar(value: max == 0 ? 0 : (value / max), color: color, height: 10),
      ],
    );
  }

  Widget _creditRow(String label, String value, Color color, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: DriverDark.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: DriverDark.grey)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _showAddExpense(LanguageProvider lang, CashflowProvider cashflow) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'expense';
    String category = 'fuel';
    showModalBottomSheet(
      context: context,
      backgroundColor: DriverDark.navy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final categories = type == 'income' ? ['fare', 'other'] : ['fuel', 'maintenance', 'food', 'sacco', 'other'];
            if (!categories.contains(category)) category = categories.first;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type == 'income' ? lang.translate('add_income') : lang.translate('add_expense'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: DriverDark.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _typeToggle(lang.translate('expenses'), type == 'expense', DriverDark.red,
                          () => setSheet(() { type = 'expense'; category = 'fuel'; }))),
                      const SizedBox(width: 8),
                      Expanded(child: _typeToggle(lang.translate('income'), type == 'income', DriverDark.greenLight,
                          () => setSheet(() { type = 'income'; category = 'fare'; }))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: categories.map((c) {
                      final sel = c == category;
                      return ChoiceChip(
                        label: Text(lang.translate(c)),
                        selected: sel,
                        onSelected: (_) => setSheet(() => category = c),
                        backgroundColor: DriverDark.card,
                        selectedColor: DriverDark.gold,
                        labelStyle: TextStyle(color: sel ? DriverDark.dark : DriverDark.greyLight, fontSize: 12),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: DriverDark.white),
                    decoration: _darkInput(lang.translate('amount'), 'TZS '),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: TextStyle(color: DriverDark.white),
                    decoration: _darkInput(lang.translate('description'), null),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (amt <= 0) return;
                        await cashflow.addTransaction(
                            type: type, amount: amt, category: category, description: descCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type == 'income' ? DriverDark.green : DriverDark.gold,
                        foregroundColor: DriverDark.dark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(lang.translate('submit'),
                          style: TextStyle(fontWeight: FontWeight.w700, color: DriverDark.dark)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _darkInput(String label, String? prefix) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      labelStyle: TextStyle(color: DriverDark.grey),
      prefixStyle: TextStyle(color: DriverDark.white),
      filled: true,
      fillColor: DriverDark.card,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DriverDark.cardBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DriverDark.gold)),
    );
  }

  Widget _typeToggle(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : DriverDark.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: selected ? DriverDark.dark : DriverDark.grey)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB — CREDIT (AI) — "RIDER PROFILE FOR BANK REVIEW"
  // ════════════════════════════════════════════════════════
  Future<void> _runCredit() async {
    setState(() => _creditLoading = true);
    try {
      final res = await _api.post('/credit/analyze');
      if (mounted) setState(() => _credit = (res as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('credit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: DriverDark.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _creditLoading = false);
    }
  }

  Color _recColor(String rec) {
    switch (rec) {
      case 'APPROVE': return DriverDark.greenLight;
      case 'CONDITIONAL': return DriverDark.gold;
      default: return DriverDark.red;
    }
  }

  void _showQrCodeBottomSheet(LanguageProvider lang, String phone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DriverDark.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.locale == 'en' ? 'My QR Code' : 'QR Code Yangu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DriverDark.white),
              ),
              const SizedBox(height: 8),
              Text(
                lang.locale == 'en'
                    ? 'Show this QR code to the station operator to scan'
                    : 'Onyesha QR Code hii kwa mhudumu wa kituo ili ascan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: DriverDark.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DriverDark.gold, width: 2),
                ),
                child: QrImageView(
                  data: phone.isNotEmpty ? phone : 'chapgo_driver_unknown',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _recLabel(String rec, LanguageProvider lang) {
    switch (rec) {
      case 'APPROVE': return lang.translate('credit_approve');
      case 'CONDITIONAL': return lang.translate('credit_conditional');
      default: return lang.translate('credit_decline');
    }
  }

  Widget _buildCreditTab(LanguageProvider lang) {
    final c = _credit;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Text(lang.translate('credit_title'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: DriverDark.gold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(lang.translate('credit_subtitle'),
            style: TextStyle(fontSize: 12, color: DriverDark.grey, height: 1.4)),
        const SizedBox(height: 16),

        if (c == null)
          DCard(
            child: Column(
              children: [
                Icon(Icons.analytics_outlined, size: 44, color: DriverDark.grey),
                const SizedBox(height: 12),
                Text(lang.translate('credit_none_yet'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: DriverDark.grey, height: 1.5)),
              ],
            ),
          )
        else ...[
          // Recommendation banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _recColor(c['recommendation'] as String? ?? 'DECLINE').withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _recColor(c['recommendation'] as String? ?? 'DECLINE').withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: _recColor(c['recommendation'] as String? ?? 'DECLINE')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.translate('credit_recommendation'),
                          style: TextStyle(fontSize: 11, color: DriverDark.grey)),
                      Text(_recLabel(c['recommendation'] as String? ?? 'DECLINE', lang),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                              color: _recColor(c['recommendation'] as String? ?? 'DECLINE'))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_num(c['score']).round()}/1000',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: DriverDark.white)),
                    Text((c['tier'] as String? ?? 'new').toUpperCase(),
                        style: TextStyle(fontSize: 11, color: DriverDark.tierColor(c['tier'] as String? ?? 'new'))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          DCard(
            child: Column(
              children: [
                _creditRow(lang.translate('credit_loan_limit'), fmtTsh(_num(c['loan_limit'])), DriverDark.gold),
                _creditRow(lang.translate('credit_interest'), '${_num(c['interest_rate']).round()}% p.a.', DriverDark.white),
                _creditRow(lang.translate('credit_monthly_income'), fmtTsh(_num(c['monthly_income'])), DriverDark.greenLight),
                _creditRow(lang.translate('credit_dti'), '${_num(c['debt_to_income_ratio']).round()}%', DriverDark.white),
                _creditRow(lang.translate('credit_max_repayment'), '${fmtTsh(_num(c['max_affordable_repayment']))} /mo', DriverDark.white, last: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if ((c['strengths'] as List?)?.isNotEmpty ?? false)
            _creditList(lang.translate('credit_strengths'), (c['strengths'] as List).cast<dynamic>(), DriverDark.greenLight, Icons.check_circle_outline),
          if ((c['risk_factors'] as List?)?.isNotEmpty ?? false)
            _creditList(lang.translate('credit_risk_factors'), (c['risk_factors'] as List).cast<dynamic>(), DriverDark.red, Icons.warning_amber_rounded),
          if ((c['conditions'] as List?)?.isNotEmpty ?? false)
            _creditList(lang.translate('credit_conditions'), (c['conditions'] as List).cast<dynamic>(), DriverDark.gold, Icons.rule),

          DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.translate('credit_summary'),
                    style: TextStyle(fontSize: 12, color: DriverDark.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(lang.locale == 'sw' ? (c['narrative_sw'] as String? ?? '') : (c['narrative_en'] as String? ?? ''),
                    style: TextStyle(fontSize: 13, color: DriverDark.white, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _creditLoading ? null : _runCredit,
            icon: _creditLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverDark.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: Text(lang.translate('credit_run'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _creditList(String title, List<dynamic> items, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: color, letterSpacing: 1, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(it.toString(),
                          style: TextStyle(fontSize: 13, color: DriverDark.white, height: 1.4))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB — SCAN (TODAY) / HISTORY
  // ════════════════════════════════════════════════════════
  Widget _buildHistoryTab(LanguageProvider lang) {
    final litres = _num(_scanTotals['total_liters']);
    final spent = _num(_scanTotals['total_amount_tsh']);
    final count = _num(_scanTotals['scan_count']).round();
    final user = context.read<AuthProvider>().user;
    final phone = _profile?['phone'] as String? ?? user?.phone ?? '';

    return RefreshIndicator(
      color: DriverDark.gold,
      backgroundColor: DriverDark.navy,
      onRefresh: () => _loadData(silent: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(lang.translate('scan_history_title'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: DriverDark.white)),
          const SizedBox(height: 16),

          // Show QR Code quick action card
          GestureDetector(
            onTap: () => _showQrCodeBottomSheet(lang, phone),
            child: DCard(
              borderColor: DriverDark.gold.withValues(alpha: 0.3),
              fill: DriverDark.gold.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, size: 36, color: Color(0xFFD4A843)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.locale == 'en' ? 'Show QR Code for Scan' : 'Onyesha QR Code ya Skani',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DriverDark.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lang.locale == 'en'
                              ? 'Show to station operator to log fuel purchase'
                              : 'Onyesha mhudumu wa kituo ili kurekodi mafuta',
                          style: TextStyle(fontSize: 11, color: DriverDark.greyLight),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: DriverDark.gold),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          DStatGrid(cards: [
            DStatCard(value: '$count', label: lang.translate('scan_count_label'), valueColor: DriverDark.greenLight),
            DStatCard(value: '${litres.toStringAsFixed(0)}L', label: lang.translate('litres_30d'), valueColor: DriverDark.gold),
            DStatCard(value: fmtTsh(spent), label: lang.translate('fuel_spent_30d')),
            DStatCard(value: '$_daysActive', label: lang.translate('days_active_short'), valueColor: DriverDark.greenLight),
          ]),
          const SizedBox(height: 8),
          DSectionHead(title: lang.translate('recent_scans')),
          DCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _scans.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(lang.translate('no_scans_yet'),
                          style: TextStyle(color: DriverDark.grey, fontStyle: FontStyle.italic)),
                    ),
                  )
                : Column(
                    children: _scans.map((s) {
                      return DListItem(
                        emoji: '⛽',
                        emojiBg: DriverDark.green.withValues(alpha: 0.12),
                        title: s['station_name'] as String? ?? 'Station',
                        meta: '${_fmtDate(s['scanned_at'])} · ${(s['payment_method'] ?? 'cash').toString()}',
                        trailing: DTrailingValue(
                          amount: '${_num(s['liters']).toStringAsFixed(1)}L',
                          unit: fmtTsh(_num(s['amount_tsh'])),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB 4 — PROFILE
  // ════════════════════════════════════════════════════════
  Widget _buildProfileTab(LanguageProvider lang) {
    final user = context.watch<AuthProvider>().user;
    final name = _profile?['full_name'] as String? ?? user?.fullName ?? 'Driver';
    final phone = _profile?['phone'] as String? ?? user?.phone ?? '';
    final chapgoId = _profile?['chapgo_id'] as String? ?? '';
    final plate = _profile?['vehicle_plate'] as String?;
    final vtype = _profile?['vehicle_type'] as String?;
    final saccoName = _profile?['sacco_name'] as String?;
    final tierColor = DriverDark.tierColor(_tier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: DriverDark.gold,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'D',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: DriverDark.dark)),
              ),
              const SizedBox(height: 12),
              Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: DriverDark.white)),
              const SizedBox(height: 4),
              Text('$phone${chapgoId.isNotEmpty ? ' · $chapgoId' : ''}',
                  style: TextStyle(fontSize: 13, color: DriverDark.grey)),
              const SizedBox(height: 8),
              DBadge(text: '${_tier.toUpperCase()} · ${_score.round()} pts', color: tierColor),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              if (plate != null)
                DListItem(emoji: '🏍️', title: lang.translate('plate_field'), meta: '$plate${vtype != null ? ' · $vtype' : ''}'),
              if (saccoName != null)
                DListItem(emoji: '🏛️', title: 'SACCO', meta: saccoName),
              DListItem(
                emoji: '📍',
                title: lang.translate('residential_address_field'),
                meta: (_profile?['district'] as String?) ?? '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _profileLink('🔳', lang.translate('menu_qr'), () => Navigator.pushNamed(context, '/driver/qr-code')),
              _profileLink('🏛️', lang.locale == 'en' ? 'My SACCOs' : 'SACCO Zangu',
                  () => Navigator.pushNamed(context, '/driver/saccos')),
              _profileLink('🏦', lang.translate('menu_loan_list'), () => Navigator.pushNamed(context, '/driver/loans/list')),
              _profileLink('⛽', lang.translate('menu_stations'),
                  () => Navigator.pushNamed(context, '/driver/stations/map', arguments: {'tab': 0})),
              _profileLink('📊', lang.translate('menu_report'),
                  () => Navigator.pushNamed(context, '/driver/reports/evaluation')),
              _profileLink('📈', lang.translate('boda_score'),
                  () => Navigator.pushNamed(context, '/driver/score').then((_) => _loadData(silent: true))),
              _profileLink('✏️', lang.translate('profile'),
                  () => Navigator.pushNamed(context, '/driver/profile').then((_) => _loadData(silent: true))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              nav.pushNamedAndRemoveUntil('/', (_) => false);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: DriverDark.red,
              side: BorderSide(color: DriverDark.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(lang.translate('sign_out_confirm')),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('Chapgo · Phase 1 Pilot',
              style: TextStyle(fontSize: 10, color: DriverDark.grey)),
        ),
      ],
    );
  }

  Widget _profileLink(String emoji, String label, VoidCallback onTap) {
    return DListItem(
      emoji: emoji,
      title: label,
      trailing: Icon(Icons.chevron_right, color: DriverDark.grey, size: 20),
      onTap: onTap,
    );
  }

  // ─── helpers ──────────────────────────────────────────────
  String _catEmoji(String cat) {
    switch (cat) {
      case 'fuel': return '⛽';
      case 'maintenance': return '🔧';
      case 'food': return '🍛';
      case 'sacco': return '🏛️';
      case 'fare': return '💰';
      default: return '📝';
    }
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today, $h:$m';
      return '${d.day}/${d.month}, $h:$m';
    } catch (_) {
      return raw.toString().split('T').first;
    }
  }
}

// ─── Animated ringing bell ────────────────────────────────
class RingingBell extends StatefulWidget {
  final int count;
  final VoidCallback onTap;
  const RingingBell({super.key, required this.count, required this.onTap});

  @override
  State<RingingBell> createState() => _RingingBellState();
}

class _RingingBellState extends State<RingingBell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _update();
  }

  @override
  void didUpdateWidget(RingingBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    if (widget.count > 0) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween<double>(begin: -0.06, end: 0.06)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.linear)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(widget.count > 0 ? Icons.notifications_active : Icons.notifications_none,
                color: DriverDark.white),
            onPressed: widget.onTap,
          ),
          if (widget.count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: DriverDark.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('${widget.count}',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}
