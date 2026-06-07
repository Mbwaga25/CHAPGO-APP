import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/cashflow_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  final _api = ApiService();
  double _score = 0;
  String _tier = 'unranked';
  double _totalLoansValue = 0.0;
  bool _loading = true;
  bool _hasLoadedData = false;
  bool _dataLoadedOnce = false;
  List<dynamic> _loansList = [];
  Map<String, dynamic>? _eligibility;

  int _unreadNotificationsCount = 0;
  String _dashboardDateFilter = 'today';

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'fuel';

  final _incomeController = TextEditingController(text: '20000');
  final _expenseController = TextEditingController(text: '8000');

  double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  bool _tabHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CashflowProvider>().setApi(_api);
      });
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
        if (mounted) {
          _loadData();
          _loadNotifications();
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _incomeController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await _api.get('/driver/notifications');
      final list = res['notifications'] as List? ?? [];
      final unread = list.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
      if (mounted) setState(() => _unreadNotificationsCount = unread);
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }
  }

  Future<void> _loadData({bool? silent}) async {
    final bool isSilent = silent ?? _hasLoadedData;
    if (!isSilent) {
      setState(() => _loading = true);
    }
    try {
      final scoreRes = await _api.get('/scores/me');
      if (mounted) {
        setState(() {
          _score = _parseNum(scoreRes['score']);
          _tier = scoreRes['tier'] as String? ?? 'unranked';
          _eligibility = scoreRes['loan_eligibility'] as Map<String, dynamic>?;
        });
      }

      final loansRes = await _api.get('/loans/me');
      List<dynamic> list = [];
      if (loansRes is Map && loansRes['loans'] is List) {
        list = loansRes['loans'];
      } else if (loansRes is List) {
        list = loansRes;
      }
      double total = 0.0;
      for (var loan in list) {
        if (loan['status'] == 'active' || loan['status'] == 'approved' || loan['status'] == 'disbursed') {
          total += _parseNum(loan['amount_tsh']);
        }
      }
      if (mounted) {
        setState(() {
          _loansList = list;
          _totalLoansValue = total;
          _hasLoadedData = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load backend score/loans: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isTxInDateRange(DateTime txDate, String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(txDate.year, txDate.month, txDate.day);
    switch (preset) {
      case 'today':
        return txDay == today;
      case 'yesterday':
        return txDay == today.subtract(const Duration(days: 1));
      case 'weekly':
        return !txDay.isBefore(today.subtract(const Duration(days: 7)));
      case 'monthly':
        return !txDay.isBefore(today.subtract(const Duration(days: 30)));
      case '6months':
        return !txDay.isBefore(today.subtract(const Duration(days: 180)));
      case 'yearly':
        return !txDay.isBefore(today.subtract(const Duration(days: 365)));
      default:
        return true;
    }
  }

  void _addCashflowTransaction(LanguageProvider lang, CashflowProvider cashflow) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final desc = _descriptionController.text.trim();
    if (amount <= 0) {
      _showSnackbar(lang.translate('error'), AppTheme.red);
      return;
    }
    final categoryStr = _selectedCategory == 'other' && _customCategoryController.text.trim().isNotEmpty
        ? _customCategoryController.text.trim()
        : _selectedCategory;
    await cashflow.addTransaction(type: _selectedType, amount: amount, category: categoryStr, description: desc);
    _amountController.clear();
    _descriptionController.clear();
    _customCategoryController.clear();
    _showSnackbar(lang.translate('success'), AppTheme.green);
    setState(() => _currentIndex = 0);
    _loadData(silent: true);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final lang = context.watch<LanguageProvider>();
    final cashflow = context.watch<CashflowProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(lang.translate('driver_title')),
        actions: [
          TextButton(
            onPressed: () {
              final newLocale = lang.locale == 'en' ? 'sw' : 'en';
              lang.setLocale(newLocale);
            },
            child: Text(
              lang.locale == 'en' ? '🇹🇿 SW' : '🇬🇧 EN',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          RingingBell(
            count: _unreadNotificationsCount,
            onTap: () => Navigator.pushNamed(context, '/driver/notifications').then((_) => _loadNotifications()),
          ),
        ],
      ),
      drawer: _buildDrawer(user, lang),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboard(user, lang, cashflow),
                _buildCashflowLogger(lang, cashflow),
                _buildScoreTab(lang),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(lang),
    );
  }

  Widget _buildBottomNav(LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_outlined, Icons.dashboard, lang.translate('overview')),
              _navItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet,
                  '${lang.translate('income')} / ${lang.translate('expenses')}'),
              _navItem(2, Icons.trending_up_outlined, Icons.trending_up, lang.translate('boda_score')),
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

  Widget _buildDrawer(user, LanguageProvider lang) {
    return Drawer(
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.gold,
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage('${ApiConfig.apiBase.replaceAll('/api/v1', '')}${user!.profileImageUrl}') as ImageProvider
                      : null,
                  child: user?.profileImageUrl == null
                      ? Text(user?.initials ?? 'D',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Driver',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(user?.phone ?? '',
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
                _drawerItem(Icons.dashboard, lang.translate('overview'), () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                }),
                const Divider(height: 1),
                _drawerExpansion(Icons.account_balance, lang.translate('menu_sacco') ?? 'SACCO & Loans', [
                  _drawerSubItem(Icons.add_circle_outline, lang.translate('menu_apply_loan') ?? 'Apply for Loan', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/driver/loans').then((_) => _loadData(silent: true));
                  }),
                  _drawerSubItem(Icons.list_alt, lang.translate('menu_loan_list') ?? 'Loan List', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/driver/loans/list');
                  }),
                ]),
                const Divider(height: 1),
                _drawerExpansion(Icons.local_gas_station, lang.translate('menu_stations') ?? 'Fuel Stations', [
                  _drawerSubItem(Icons.map, lang.translate('menu_stations_map') ?? 'Live on Map', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/driver/stations/map', arguments: {'tab': 0});
                  }),
                  _drawerSubItem(Icons.list, lang.translate('menu_stations_list') ?? 'List of Stations', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/driver/stations/map', arguments: {'tab': 1});
                  }),
                ]),
                const Divider(height: 1),
                _drawerItem(Icons.assessment, lang.translate('menu_report') ?? 'Report & Evaluation', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/driver/reports/evaluation');
                }),
                const Divider(height: 1),
                _drawerItem(Icons.person, lang.translate('profile'), () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/driver/profile').then((_) => _loadData(silent: true));
                }),
                _drawerItem(Icons.qr_code, lang.translate('qr_code'), () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/driver/qr-code');
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
            title: Text(lang.translate('sign_out'),
                style: const TextStyle(color: AppTheme.red, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
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

  Widget _drawerSubItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      leading: Icon(icon, color: AppTheme.gold, size: 18),
      title: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _drawerExpansion(IconData icon, String label, List<Widget> children) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.navy.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.navy, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      childrenPadding: EdgeInsets.zero,
      children: children,
    );
  }

  // ─── DASHBOARD TAB ───────────────────────────────────
  Widget _buildDashboard(user, LanguageProvider lang, CashflowProvider cashflow) {
    final filteredTxs = cashflow.transactions
        .where((t) => _isTxInDateRange(t.date, _dashboardDateFilter))
        .toList();
    final double displayIncome =
        filteredTxs.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final double displayExpense =
        filteredTxs.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData(silent: true);
        await _loadNotifications();
      },
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // ─── Hero Header ──────────────────────────────
          Container(
            margin: const EdgeInsets.all(0),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.gold,
                      backgroundImage: user?.profileImageUrl != null
                          ? NetworkImage('${ApiConfig.apiBase.replaceAll('/api/v1', '')}${user!.profileImageUrl}') as ImageProvider
                          : null,
                      child: user?.profileImageUrl == null
                          ? Text(user?.initials ?? 'D',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Driver',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(user?.phone ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    // Tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _tierColor(_tier).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _tierColor(_tier).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: _tierColor(_tier)),
                          const SizedBox(width: 4),
                          Text(
                            _tier.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _tierColor(_tier),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Score mini bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate('boda_score'),
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${_score.round()}',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              const Text('/100', style: TextStyle(fontSize: 14, color: Colors.white54)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_score / 100).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(_tierColor(_tier)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Quick actions column
                    Column(
                      children: [
                        _heroActionBtn(Icons.qr_code, lang.translate('qr_code'), () {
                          Navigator.pushNamed(context, '/driver/qr-code');
                        }),
                        const SizedBox(height: 8),
                        _heroActionBtn(Icons.person_outline, lang.translate('profile'), () {
                          Navigator.pushNamed(context, '/driver/profile').then((_) => _loadData(silent: true));
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('filter_date'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dashboardDateFilter,
                          isDense: true,
                          onChanged: (val) { if (val != null) setState(() => _dashboardDateFilter = val); },
                          items: [
                            DropdownMenuItem(value: 'today', child: Text(lang.translate('preset_today'), style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'yesterday', child: Text(lang.translate('preset_yesterday'), style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'weekly', child: Text(lang.translate('preset_weekly'), style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'monthly', child: Text(lang.translate('preset_monthly'), style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'all', child: Text(lang.translate('preset_all'), style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stat Cards
                Row(
                  children: [
                    Expanded(child: _statCard(lang.translate('income'), 'TSh ${displayIncome.toStringAsFixed(0)}',
                        AppTheme.green, Icons.arrow_downward,
                        onTap: () => Navigator.pushNamed(context, '/driver/cashflow', arguments: {'tab': 'income'}))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(lang.translate('expenses'), 'TSh ${displayExpense.toStringAsFixed(0)}',
                        AppTheme.red, Icons.arrow_upward,
                        onTap: () => Navigator.pushNamed(context, '/driver/cashflow', arguments: {'tab': 'expense'}))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard(lang.translate('loans'), 'TSh ${_totalLoansValue.toStringAsFixed(0)}',
                        AppTheme.orange, Icons.assignment_outlined,
                        onTap: () => Navigator.pushNamed(context, '/driver/loans/list'))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(lang.translate('boda_score'), '$_score',
                        AppTheme.accent, Icons.trending_up,
                        onTap: () => Navigator.pushNamed(context, '/driver/reports/evaluation'))),
                  ],
                ),

                const SizedBox(height: 24),

                // Recent transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('recent_activities'),
                        style: AppTheme.headingSmall),
                    if (filteredTxs.length > 8)
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/driver/cashflow'),
                        child: Text(lang.translate('view_more') ?? 'View All',
                            style: const TextStyle(fontSize: 12, color: AppTheme.accent)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (filteredTxs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.grayLight),
                          const SizedBox(height: 10),
                          Text(lang.translate('no_activities'),
                              style: const TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(filteredTxs.length.clamp(0, 8), (i) {
                    final tx = filteredTxs[i];
                    final isIncome = tx.type == 'income';
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
                              color: (isIncome ? AppTheme.green : AppTheme.red).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isIncome ? AppTheme.green : AppTheme.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang.translate(tx.category),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                if (tx.description.isNotEmpty)
                                  Text(tx.description,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncome ? "+" : "-"} TSh ${tx.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isIncome ? AppTheme.green : AppTheme.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.navy.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.grayLight),
              ],
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum': return AppTheme.teal;
      case 'gold': return AppTheme.gold;
      case 'silver': return AppTheme.grayLight;
      case 'bronze': return const Color(0xFFCD7F32);
      default: return AppTheme.gray;
    }
  }

  // ─── CASHFLOW LOGGER TAB ──────────────────────────────
  Widget _buildCashflowLogger(LanguageProvider lang, CashflowProvider cashflow) {
    final categories = _selectedType == 'income'
        ? ['fare', 'other']
        : ['fuel', 'maintenance', 'food', 'sacco', 'other'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == 'income' ? lang.translate('add_income') : lang.translate('add_expense'),
            style: AppTheme.headingLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _selectedType == 'income'
                ? (lang.locale == 'en' ? 'Record your earnings for the day' : 'Rekodi mapato yako ya siku')
                : (lang.locale == 'en' ? 'Track your spending' : 'Fuatilia matumizi yako'),
            style: const TextStyle(fontSize: 13, color: AppTheme.gray),
          ),
          const SizedBox(height: 20),

          // Type toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(child: _typeToggleBtn(lang.translate('expenses'), _selectedType == 'expense', AppTheme.red, () {
                  setState(() { _selectedType = 'expense'; _selectedCategory = 'fuel'; });
                })),
                const SizedBox(width: 4),
                Expanded(child: _typeToggleBtn(lang.translate('income'), _selectedType == 'income', AppTheme.green, () {
                  setState(() { _selectedType = 'income'; _selectedCategory = 'fare'; });
                })),
              ],
            ),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: _selectedType == 'income' ? lang.translate('income_source') : lang.translate('expense_category'),
              prefixIcon: const Icon(Icons.category_outlined, size: 20),
            ),
            items: categories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(lang.translate(cat))))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val ?? categories.first),
          ),

          if (_selectedCategory == 'other') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customCategoryController,
              decoration: InputDecoration(
                labelText: lang.translate('custom_category'),
                hintText: lang.translate('custom_category_hint'),
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: lang.translate('amount'),
              hintText: '5000',
              prefixText: 'TSh ',
              prefixIcon: const Icon(Icons.attach_money, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: lang.translate('description'),
              hintText: 'Matumizi leo',
              prefixIcon: const Icon(Icons.notes_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _addCashflowTransaction(lang, cashflow),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType == 'income' ? AppTheme.green : AppTheme.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(lang.translate('submit'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeToggleBtn(String label, bool isSelected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isSelected ? Colors.white : AppTheme.gray,
          ),
        ),
      ),
    );
  }

  // ─── SCORE / CALCULATOR TAB ───────────────────────────
  Widget _buildScoreTab(LanguageProvider lang) {
    final Color tierColor = _tierColor(_tier);

    final dailyIncome = double.tryParse(_incomeController.text.trim()) ?? 0.0;
    final dailyExpense = double.tryParse(_expenseController.text.trim()) ?? 0.0;
    final remainingCash = dailyIncome - dailyExpense;
    final superSafePay = remainingCash > 0 ? remainingCash * 0.3 : 0.0;
    final moderatePay = remainingCash > 0 ? remainingCash * 0.5 : 0.0;
    final riskyPay = remainingCash > 0 ? remainingCash * 0.7 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tierColor, tierColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: tierColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('boda_score').toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.5)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text(_tier.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${_score.round()}',
                        style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
                    const Text('/100', style: TextStyle(color: Colors.white60, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_score / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _score > 0
                            ? (lang.locale == 'en'
                                ? 'Your score is based on scans and SACCO payments.'
                                : 'Alama zako zimehesabiwa kwa miamala na marejesho ya SACCO.')
                            : lang.translate('score_not_active'),
                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Eligibility
          if (_eligibility != null && _score > 0) ...[
            Text(lang.translate('credit_limit'), style: AppTheme.headingSmall),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: const Border(left: BorderSide(color: AppTheme.accent, width: 3)),
                boxShadow: [BoxShadow(color: AppTheme.navy.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.translate('eligible_loan_range'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'TSh ${_parseNum(_eligibility!['min']).toStringAsFixed(0)} — TSh ${_parseNum(_eligibility!['max']).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.navy),
                  ),
                  const SizedBox(height: 12),
                  Text(lang.translate('eligible_products'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: (_eligibility!['products'] as List? ?? []).map<Widget>((prod) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(lang.translate(prod.toString()),
                            style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Loans
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.translate('loans'), style: AppTheme.headingSmall),
              if (_score > 0)
                ElevatedButton(
                  onPressed: () async {
                    final refresh = await Navigator.pushNamed(context, '/driver/loans');
                    if (refresh == true) _loadData(silent: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(lang.translate('apply_loan_btn'),
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_loansList.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(lang.translate('no_active_loans'),
                    style: const TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)),
              ),
            )
          else
            ..._loansList.map((loan) {
              final status = loan['status'] as String? ?? 'pending';
              final statusColor = _loanStatusColor(status);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.translate(loan['loan_purpose'] as String? ?? 'other').toUpperCase(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _loanDetailItem(lang.translate('loan_amount_label'), 'TSh ${_parseNum(loan['amount_tsh']).toStringAsFixed(0)}'),
                        _loanDetailItem(lang.translate('loan_payment_label'), 'TSh ${_parseNum(loan['monthly_payment_tsh']).toStringAsFixed(0)}'),
                        _loanDetailItem(lang.translate('loan_term_label'), '${loan['term_months'] ?? "0"} ${lang.locale == "en" ? "Mos" : "Mie"}'),
                      ],
                    ),
                    if (loan['applied_at'] != null) ...[
                      const SizedBox(height: 10),
                      Text('${lang.translate('loan_date_label')}: ${loan['applied_at'].toString().split('T').first}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
                    ],
                  ],
                ),
              );
            }).toList(),

          const SizedBox(height: 24),

          // Repayment Advisor
          Text(lang.translate('repayment_advisor'), style: AppTheme.headingSmall),
          const SizedBox(height: 4),
          Text(
            lang.locale == 'en'
                ? 'Calculate your daily budget and check what you can afford'
                : 'Piga hesabu ya bajeti yako ya siku na ujue unachoweza kumudu',
            style: const TextStyle(fontSize: 13, color: AppTheme.gray),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: lang.translate('daily_income_predict'),
              prefixText: 'TSh ',
              prefixIcon: const Icon(Icons.arrow_downward, color: AppTheme.green, size: 20),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _expenseController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: lang.translate('daily_expense_predict'),
              prefixText: 'TSh ',
              prefixIcon: const Icon(Icons.arrow_upward, color: AppTheme.red, size: 20),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          if (remainingCash <= 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.locale == 'en'
                          ? 'Warning: Expenses exceed income. You cannot afford a loan right now.'
                          : 'Tahadhari: Matumizi yanazidi kipato. Hauwezi kumudu mkopo kwa sasa.',
                      style: const TextStyle(color: AppTheme.red, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Text(lang.translate('daily_cash_remaining'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('TSh ${remainingCash.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.green)),
              ],
            ),
            const SizedBox(height: 16),
            Text(lang.translate('safe_repayment_levels'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const SizedBox(height: 10),
            _advisorTierRow(title: lang.translate('super_safe_level'), amount: superSafePay,
                description: lang.translate('super_safe_desc'), levelColor: AppTheme.green),
            const SizedBox(height: 8),
            _advisorTierRow(title: lang.translate('moderate_level'), amount: moderatePay,
                description: lang.translate('moderate_desc'), levelColor: AppTheme.orange),
            const SizedBox(height: 8),
            _advisorTierRow(title: lang.translate('risky_level'), amount: riskyPay,
                description: lang.translate('risky_desc'), levelColor: AppTheme.red),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang.locale == 'en'
                          ? 'We advise choosing a loan payment close to the Super Safe level to stay stress-free!'
                          : 'Tunakushauri kuchagua mkopo wenye marejesho ya karibu na kiwango cha Salama Kabisa!',
                      style: const TextStyle(fontSize: 12, color: AppTheme.accent, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _loanDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navy)),
      ],
    );
  }

  Widget _advisorTierRow({required String title, required double amount, required String description, required Color levelColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: levelColor, width: 3)),
        boxShadow: [BoxShadow(color: AppTheme.navy.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: levelColor)),
              Text('TSh ${amount.toStringAsFixed(0)} / ${lang.locale == "en" ? "Day" : "Siku"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navy)),
            ],
          ),
          const SizedBox(height: 5),
          Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.gray, height: 1.4)),
        ],
      ),
    );
  }

  Color _loanStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'disbursed': return AppTheme.green;
      case 'approved': return AppTheme.teal;
      case 'pending': return AppTheme.orange;
      case 'repaid': return AppTheme.navy;
      default: return AppTheme.red;
    }
  }

  LanguageProvider get lang => context.read<LanguageProvider>();
}

// ─── Animated Ringing Bell ────────────────────────────────
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
    _updateAnimation();
  }

  @override
  void didUpdateWidget(RingingBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
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
      turns: Tween<double>(begin: -0.06, end: 0.06).animate(
          CurvedAnimation(parent: _controller, curve: Curves.linear)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              widget.count > 0 ? Icons.notifications_active : Icons.notifications_none,
              color: Colors.white,
            ),
            onPressed: widget.onTap,
          ),
          if (widget.count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppTheme.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '${widget.count}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
