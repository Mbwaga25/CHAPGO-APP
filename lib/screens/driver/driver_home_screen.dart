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
  List<dynamic> _loansList = [];
  Map<String, dynamic>? _eligibility;

  // Notifications
  int _unreadNotificationsCount = 0;

  // Filter parameters
  String _dashboardDateFilter = 'today'; // Default Today

  // Form Controllers for Cashflow additions
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'fuel';

  // Calculator Controllers
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
      context.read<CashflowProvider>().setApi(_api);
    }
    
    if (!_tabHandled) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final tab = args?['tab'] as int?;
      if (tab != null) {
        _currentIndex = tab;
      }
      _tabHandled = true;
    }
    
    _loadData();
    _loadNotifications();
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
      setState(() {
        _unreadNotificationsCount = unread;
      });
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Fetch score
      final scoreRes = await _api.get('/scores/me');
      setState(() {
        _score = _parseNum(scoreRes['score']);
        _tier = scoreRes['tier'] as String? ?? 'unranked';
        _eligibility = scoreRes['loan_eligibility'] as Map<String, dynamic>?;
      });

      // Fetch loans
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
      setState(() {
        _loansList = list;
        _totalLoansValue = total;
      });
    } catch (e) {
      debugPrint('Failed to load backend score/loans: $e');
    } finally {
      setState(() => _loading = false);
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
        final yesterday = today.subtract(const Duration(days: 1));
        return txDay == yesterday;
      case 'weekly':
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        return txDay.isAfter(sevenDaysAgo) || txDay == sevenDaysAgo;
      case 'monthly':
        final thirtyDaysAgo = today.subtract(const Duration(days: 30));
        return txDay.isAfter(thirtyDaysAgo) || txDay == thirtyDaysAgo;
      case '6months':
        final sixMonthsAgo = today.subtract(const Duration(days: 180));
        return txDay.isAfter(sixMonthsAgo) || txDay == sixMonthsAgo;
      case 'yearly':
        final aYearAgo = today.subtract(const Duration(days: 365));
        return txDay.isAfter(aYearAgo) || txDay == aYearAgo;
      case 'all':
      default:
        return true;
    }
  }

  void _addCashflowTransaction(LanguageProvider lang, CashflowProvider cashflow) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final desc = _descriptionController.text.trim();

    if (amount <= 0) {
      _showSnackbar(lang.translate('error'), Colors.red);
      return;
    }

    final categoryStr = _selectedCategory == 'other' && _customCategoryController.text.trim().isNotEmpty
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    await cashflow.addTransaction(
      type: _selectedType,
      amount: amount,
      category: categoryStr,
      description: desc,
    );

    _amountController.clear();
    _descriptionController.clear();
    _customCategoryController.clear();

    _showSnackbar(lang.translate('success'), Colors.green);
    setState(() {
      _currentIndex = 0; // Switch back to Dashboard Summary
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final lang = context.watch<LanguageProvider>();
    final cashflow = context.watch<CashflowProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('driver_title')),
        actions: [
          // Language switcher button
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
            onTap: () {
              Navigator.pushNamed(context, '/driver/notifications').then((_) => _loadNotifications());
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.navy),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.gold,
                backgroundImage: user?.profileImageUrl != null
                    ? NetworkImage('${ApiConfig.apiBase.replaceAll('/api/v1', '')}${user!.profileImageUrl}') as ImageProvider
                    : null,
                child: user?.profileImageUrl == null
                    ? Text(
                        user?.initials ?? 'D',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    : null,
              ),
              accountName: Text(
                user?.fullName ?? 'Driver',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(user?.phone ?? ''),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: AppTheme.navy),
                    title: Text(lang.translate('overview')),
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  const Divider(),
                  
                  // SACCO & Loans Submenu
                  ExpansionTile(
                    leading: const Icon(Icons.account_balance, color: AppTheme.navy),
                    title: Text(lang.translate('menu_sacco') ?? 'SACCO & Loans'),
                    childrenPadding: const EdgeInsets.only(left: 16),
                    initiallyExpanded: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline, color: AppTheme.gold),
                        title: Text(lang.translate('menu_apply_loan') ?? 'Apply for Loan'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/driver/loans').then((_) => _loadData());
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.list_alt, color: AppTheme.gold),
                        title: Text(lang.translate('menu_loan_list') ?? 'Loan List'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/driver/loans/list');
                        },
                      ),
                    ],
                  ),
                  const Divider(),

                  // Stations Submenu
                  ExpansionTile(
                    leading: const Icon(Icons.local_gas_station, color: AppTheme.navy),
                    title: Text(lang.translate('menu_stations') ?? 'Fuel Stations'),
                    childrenPadding: const EdgeInsets.only(left: 16),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.map, color: AppTheme.gold),
                        title: Text(lang.translate('menu_stations_map') ?? 'Live on Map'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/driver/stations/map', arguments: {'tab': 0});
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.list, color: AppTheme.gold),
                        title: Text(lang.translate('menu_stations_list') ?? 'List of Stations'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/driver/stations/map', arguments: {'tab': 1});
                        },
                      ),
                    ],
                  ),
                  const Divider(),

                  // Reports
                  ListTile(
                    leading: const Icon(Icons.assessment, color: AppTheme.navy),
                    title: Text(lang.translate('menu_report') ?? 'Report & Evaluation'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/driver/reports/evaluation');
                    },
                  ),
                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.person, color: AppTheme.navy),
                    title: Text(lang.translate('profile')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/driver/profile').then((_) => _loadData());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code, color: AppTheme.navy),
                    title: Text(lang.translate('qr_code')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/driver/qr-code');
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(lang.translate('sign_out'), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboard(user, lang, cashflow),
                _buildCashflowLogger(lang, cashflow),
                _buildScoreCalculator(lang),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: AppTheme.grayLight,
        backgroundColor: AppTheme.white,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: lang.translate('overview'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: '${lang.translate('income')} / ${lang.translate('expenses')}',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.trending_up_outlined),
            activeIcon: const Icon(Icons.trending_up),
            label: lang.translate('boda_score'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(user, LanguageProvider lang, CashflowProvider cashflow) {
    // Dynamic filtered summaries based on the date preset
    final filteredTxs = cashflow.transactions.where((t) => _isTxInDateRange(t.date, _dashboardDateFilter)).toList();
    final double displayIncome = filteredTxs.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final double displayExpense = filteredTxs.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await _loadNotifications();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.gold,
                backgroundImage: user?.profileImageUrl != null
                    ? NetworkImage('${ApiConfig.apiBase.replaceAll('/api/v1', '')}${user!.profileImageUrl}') as ImageProvider
                    : null,
                child: user?.profileImageUrl == null
                    ? Text(
                        user?.initials ?? 'D',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.white),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Driver',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy),
                    ),
                    Text(
                      user?.phone ?? '',
                      style: const TextStyle(fontSize: 13, color: AppTheme.gray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dashboard summary date filter selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('filter_date'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 14),
              ),
              DropdownButton<String>(
                value: _dashboardDateFilter,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _dashboardDateFilter = val;
                    });
                  }
                },
                items: [
                  DropdownMenuItem(value: 'today', child: Text(lang.translate('preset_today'))),
                  DropdownMenuItem(value: 'yesterday', child: Text(lang.translate('preset_yesterday'))),
                  DropdownMenuItem(value: 'weekly', child: Text(lang.translate('preset_weekly'))),
                  DropdownMenuItem(value: 'monthly', child: Text(lang.translate('preset_monthly'))),
                  DropdownMenuItem(value: '6months', child: Text(lang.translate('preset_6months'))),
                  DropdownMenuItem(value: 'yearly', child: Text(lang.translate('preset_yearly'))),
                  DropdownMenuItem(value: 'all', child: Text(lang.translate('preset_all'))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Cashflow, Loans, and Score Summary Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _summaryBox(
                lang.translate('income'),
                'TSh ${displayIncome.toStringAsFixed(0)}',
                Colors.green,
                onTap: () => Navigator.pushNamed(context, '/driver/cashflow', arguments: {'tab': 'income'}),
              ),
              _summaryBox(
                lang.translate('expenses'),
                'TSh ${displayExpense.toStringAsFixed(0)}',
                Colors.red,
                onTap: () => Navigator.pushNamed(context, '/driver/cashflow', arguments: {'tab': 'expense'}),
              ),
              _summaryBox(
                lang.translate('loans'),
                'TSh ${_totalLoansValue.toStringAsFixed(0)}',
                Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/driver/loans/list'),
              ),
              _summaryBox(
                lang.translate('boda_score'),
                '$_score (${_tier.toUpperCase()})',
                AppTheme.gold,
                onTap: () => Navigator.pushNamed(context, '/driver/reports/evaluation'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/driver/qr-code'),
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  label: Text(lang.translate('qr_code')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navy, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/driver/profile').then((_) => _loadData()),
                  icon: const Icon(Icons.person),
                  label: Text(lang.translate('profile')),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cashflow Transactions List (Limited to 8)
          Text(
            lang.translate('recent_activities'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy),
          ),
          const SizedBox(height: 8),
          if (filteredTxs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    lang.translate('no_activities'),
                    style: const TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            )
          else ...[
            ...List.generate(filteredTxs.length.clamp(0, 8), (i) {
              final tx = filteredTxs[i];
              final isIncome = tx.type == 'income';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    lang.translate(tx.category),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    tx.description.isNotEmpty ? tx.description : '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                  ),
                  trailing: Text(
                    '${isIncome ? "+" : "-"} TSh ${tx.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            }),
            if (filteredTxs.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/driver/cashflow'),
                    child: Text(lang.translate('view_more') ?? 'View More'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600)),
                  if (onTap != null)
                    const Icon(Icons.open_in_new, size: 12, color: AppTheme.gray),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(
                label: Text(lang.translate('expenses')),
                selected: _selectedType == 'expense',
                onSelected: (val) {
                  setState(() {
                    _selectedType = 'expense';
                    _selectedCategory = 'fuel';
                  });
                },
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: Text(lang.translate('income')),
                selected: _selectedType == 'income',
                onSelected: (val) {
                  setState(() {
                    _selectedType = 'income';
                    _selectedCategory = 'fare';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: _selectedType == 'income' ? lang.translate('income_source') : lang.translate('expense_category'),
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
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: lang.translate('description'),
              hintText: 'Matumizi leo',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _addCashflowTransaction(lang, cashflow),
              child: Text(lang.translate('submit')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCalculator(LanguageProvider lang) {
    Color tierColor;
    switch (_tier.toLowerCase()) {
      case 'platinum':
        tierColor = Colors.teal.shade400;
        break;
      case 'gold':
        tierColor = AppTheme.gold;
        break;
      case 'silver':
        tierColor = Colors.blueGrey;
        break;
      case 'bronze':
        tierColor = Colors.brown;
        break;
      default:
        tierColor = AppTheme.gray;
    }

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
          // 1. Boda Score Banner Card
          Card(
            color: tierColor,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.translate('boda_score').toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          _tier.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_score.round()}',
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/100',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _score > 0
                              ? (lang.locale == 'en'
                                  ? 'Your score is based on scans and SACCO payments.'
                                  : 'Alama zako zimehesabiwa kwa miamala na marejesho ya SACCO.')
                              : lang.translate('score_not_active'),
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Credit Eligibility Limits
          if (_eligibility != null && _score > 0) ...[
            Text(
              lang.translate('credit_limit'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.translate('eligible_loan_range'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TSh ${_parseNum(_eligibility!['min']).toStringAsFixed(0)} - TSh ${_parseNum(_eligibility!['max']).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang.translate('eligible_products'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: ( _eligibility!['products'] as List? ?? []).map<Widget>((prod) {
                        return Chip(
                          label: Text(lang.translate(prod.toString())),
                          backgroundColor: AppTheme.navy.withOpacity(0.05),
                          labelStyle: const TextStyle(color: AppTheme.navy, fontSize: 11, fontWeight: FontWeight.w600),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. My Loans List Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('loans'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
              ),
              if (_score > 0)
                ElevatedButton(
                  onPressed: () async {
                    final refresh = await Navigator.pushNamed(context, '/driver/loans');
                    if (refresh == true) {
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    lang.translate('apply_loan_btn'),
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loansList.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    lang.translate('no_active_loans'),
                    style: const TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            ..._loansList.map((loan) {
              final status = loan['status'] as String? ?? 'pending';
              Color statusColor;
              switch (status.toLowerCase()) {
                case 'active':
                case 'disbursed':
                  statusColor = Colors.green;
                  break;
                case 'approved':
                  statusColor = Colors.teal;
                  break;
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'repaid':
                  statusColor = AppTheme.navy;
                  break;
                default:
                  statusColor = Colors.red;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.translate(loan['loan_purpose'] as String? ?? 'other').toUpperCase(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navy),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
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
                        Text(
                          '${lang.translate('loan_date_label')}: ${loan['applied_at'].toString().split('T').first}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.gray),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 24),

          // 4. Smart Repayment Advisor
          Text(
            lang.translate('repayment_advisor'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _expenseController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: lang.translate('daily_expense_predict'),
              prefixText: 'TSh ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          if (remainingCash <= 0) ...[
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.locale == 'en'
                            ? 'Warning: Your expenses match or exceed your income. You cannot afford a loan right now. Try to reduce expenses or increase daily earnings.'
                            : 'Tahadhari: Matumizi yako yanazidi au kulingana na kipato chako cha siku. Hauwezi kumudu mkopo kwa sasa. Punguza matumizi au ongeza kipato.',
                        style: TextStyle(color: Colors.red.shade900, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              lang.translate('daily_cash_remaining'),
              style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'TSh ${remainingCash.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              lang.translate('safe_repayment_levels'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),

            _advisorTierRow(
              title: lang.translate('super_safe_level'),
              amount: superSafePay,
              description: lang.translate('super_safe_desc'),
              levelColor: Colors.green,
            ),
            const SizedBox(height: 8),
            _advisorTierRow(
              title: lang.translate('moderate_level'),
              amount: moderatePay,
              description: lang.translate('moderate_desc'),
              levelColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            _advisorTierRow(
              title: lang.translate('risky_level'),
              amount: riskyPay,
              description: lang.translate('risky_desc'),
              levelColor: Colors.red,
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang.locale == 'en'
                          ? 'We advise choosing a loan payment close to the Super Safe level to stay stress-free!'
                          : 'Tunakushauri kuchagua mkopo wenye marejesho ya karibu na kiwango cha Salama Kabisa ili uepuke shinikizo!',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _advisorTierRow({
    required String title,
    required double amount,
    required String description,
    required Color levelColor,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: levelColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: levelColor),
                ),
                Text(
                  'TSh ${amount.toStringAsFixed(0)} / ${context.read<LanguageProvider>().locale == "en" ? "Day" : "Siku"}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navy),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppTheme.gray, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Ringing Bell widget
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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
    final Tween<double> rotationTween = Tween<double>(begin: -0.12, end: 0.12);
    return RotationTransition(
      turns: rotationTween.animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      )),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: widget.onTap,
          ),
          if (widget.count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '${widget.count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
