import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/cashflow_provider.dart';
import '../../widgets/driver_subpage_navbar.dart';

class DriverCashflowPage extends StatefulWidget {
  const DriverCashflowPage({super.key});

  @override
  State<DriverCashflowPage> createState() => _DriverCashflowPageState();
}

class _DriverCashflowPageState extends State<DriverCashflowPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filtering states
  String _dateFilter = 'today'; // Default: Today
  final _minAmountController = TextEditingController();
  final _searchController = TextEditingController();

  // Pagination parameters
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentPage = 1; // Reset page on tab switch
      });
    });
    _minAmountController.addListener(() => setState(() => _currentPage = 1));
    _searchController.addListener(() => setState(() => _currentPage = 1));
  }

  bool _tabHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabHandled) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('tab')) {
        final tabArg = args['tab'];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              if (tabArg == 'income' || tabArg == 0) {
                _tabController.index = 0;
              } else if (tabArg == 'expense' || tabArg == 1) {
                _tabController.index = 1;
              }
            });
          }
        });
      }
      _tabHandled = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _minAmountController.dispose();
    _searchController.dispose();
    super.dispose();
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

  List<CashflowTransaction> _getFilteredTransactions(List<CashflowTransaction> all, String type) {
    final minAmt = double.tryParse(_minAmountController.text.trim()) ?? 0.0;
    final query = _searchController.text.toLowerCase().trim();

    return all.where((t) {
      // Type match
      if (t.type != type) return false;
      // Date filter
      if (!_isTxInDateRange(t.date, _dateFilter)) return false;
      // Min amount filter
      if (t.amount < minAmt) return false;
      // Text query match
      if (query.isNotEmpty) {
        final catMatch = t.category.toLowerCase().contains(query);
        final descMatch = t.description.toLowerCase().contains(query);
        if (!catMatch && !descMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final cashflow = context.watch<CashflowProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${lang.translate('income')} & ${lang.translate('expenses')}'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          tabs: [
            Tab(text: lang.translate('income')),
            Tab(text: lang.translate('expenses')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _dateFilter,
                        decoration: InputDecoration(
                          labelText: lang.translate('filter_date') ?? 'Date Preset',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _dateFilter = val;
                              _currentPage = 1;
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.translate('filter_amount') ?? 'Min TSh',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reason / category...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Total Sum Summary Card
          Builder(
            builder: (context) {
              final activeType = _tabController.index == 0 ? 'income' : 'expense';
              final filteredForTotal = _getFilteredTransactions(cashflow.transactions, activeType);
              final double totalSum = filteredForTotal.fold(0.0, (sum, tx) => sum + tx.amount);
              final isIncome = activeType == 'income';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isIncome ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isIncome
                          ? '${lang.translate('total_income') ?? 'Total Income'} (${filteredForTotal.length} items)'
                          : '${lang.translate('total_expenses') ?? 'Total Expenses'} (${filteredForTotal.length} items)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green.shade900 : Colors.red.shade900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'TSh ${totalSum.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green.shade900 : Colors.red.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
          ),

          // Transactions list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(cashflow.transactions, 'income', lang),
                _buildList(cashflow.transactions, 'expense', lang),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DriverSubPageNavBar(activeIndex: 1),
    );
  }

  Widget _buildList(List<CashflowTransaction> all, String type, LanguageProvider lang) {
    final filtered = _getFilteredTransactions(all, type);
    final totalItems = filtered.length;
    final totalPages = (totalItems / _pageSize).ceil();
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final paginatedList = filtered.isEmpty ? [] : filtered.sublist(startIndex, endIndex);

    if (paginatedList.isEmpty) {
      return Center(
        child: Text(
          lang.translate('no_activities'),
          style: const TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic),
        ),
      );
    }

    final isIncome = type == 'income';

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paginatedList.length,
            itemBuilder: (context, i) {
              final tx = paginatedList[i];
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
            },
          ),
        ),
        // Pagination Controls
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: const Border(top: BorderSide(color: AppTheme.grayLight, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  '${lang.translate('page_label') ?? 'Page'} $_currentPage / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
