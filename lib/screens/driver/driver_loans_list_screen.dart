import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/driver_subpage_navbar.dart';

class DriverLoansListScreen extends StatefulWidget {
  final String? initialFilter;
  const DriverLoansListScreen({super.key, this.initialFilter});

  @override
  State<DriverLoansListScreen> createState() => _DriverLoansListScreenState();
}

class _DriverLoansListScreenState extends State<DriverLoansListScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _allLoans = [];
  late TabController _tabController;

  // Pagination parameters
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _loadLoans();

    // Check if initialFilter requires setting active tab to Success
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final filter = args?['filter'] ?? widget.initialFilter;
      if (filter == 'success') {
        _tabController.index = 0; // Success Tab
      } else if (filter == 'pending') {
        _tabController.index = 1; // Pending Tab
      } else if (filter == 'rejected') {
        _tabController.index = 2; // Rejected Tab
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/loans/me');
      List<dynamic> list = [];
      if (res is Map && res['loans'] is List) {
        list = res['loans'];
      } else if (res is List) {
        list = res;
      }
      setState(() {
        _allLoans = list;
      });
    } catch (e) {
      debugPrint('Failed to load loans: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getFilteredLoans(int tabIndex) {
    switch (tabIndex) {
      case 0: // Success / Active
        return _allLoans.where((loan) {
          final s = (loan['status'] as String? ?? '').toLowerCase();
          return s == 'approved' || s == 'active' || s == 'repaid' || s == 'disbursed';
        }).toList();
      case 1: // Pending
        return _allLoans.where((loan) {
          final s = (loan['status'] as String? ?? '').toLowerCase();
          return s == 'pending';
        }).toList();
      case 2: // Rejected
        return _allLoans.where((loan) {
          final s = (loan['status'] as String? ?? '').toLowerCase();
          return s == 'denied' || s == 'rejected';
        }).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('menu_loan_list')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          tabs: [
            Tab(text: lang.translate('tab_success')),
            Tab(text: lang.translate('tab_pending')),
            Tab(text: lang.translate('tab_rejected')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top filter selector to quickly switch tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lang.translate('filter_date')}:',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                      ),
                      DropdownButton<String>(
                        value: _tabController.index == 0
                            ? 'success'
                            : (_tabController.index == 1 ? 'pending' : 'rejected'),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _currentPage = 1;
                              if (val == 'success') _tabController.index = 0;
                              if (val == 'pending') _tabController.index = 1;
                              if (val == 'rejected') _tabController.index = 2;
                            });
                          }
                        },
                        items: [
                          DropdownMenuItem(value: 'success', child: Text(lang.translate('tab_success'))),
                          DropdownMenuItem(value: 'pending', child: Text(lang.translate('tab_pending'))),
                          DropdownMenuItem(value: 'rejected', child: Text(lang.translate('tab_rejected'))),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      final filtered = _getFilteredLoans(_tabController.index);
                      
                      // Calculate paginated sublist
                      final totalItems = filtered.length;
                      final totalPages = (totalItems / _pageSize).ceil();
                      final startIndex = (_currentPage - 1) * _pageSize;
                      final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
                      final paginatedList = filtered.isEmpty ? [] : filtered.sublist(startIndex, endIndex);

                      return Column(
                        children: [
                          Expanded(
                            child: paginatedList.isEmpty
                                ? Center(
                                    child: Text(
                                      lang.translate('no_active_loans'),
                                      style: const TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: paginatedList.length,
                                    itemBuilder: (context, i) {
                                      final loan = paginatedList[i];
                                      final purpose = loan['loan_purpose'] as String? ?? 'general';
                                      final amount = double.tryParse(loan['amount_tsh']?.toString() ?? '') ?? 0.0;
                                      final term = loan['term_months'] as int? ?? 12;
                                      final monthly = double.tryParse(loan['monthly_payment_tsh']?.toString() ?? '') ?? 0.0;
                                      final status = loan['status'] as String? ?? 'pending';
                                      final dateStr = loan['applied_at'] != null
                                          ? DateTime.parse(loan['applied_at']).toLocal().toString().substring(0, 10)
                                          : '';

                                      Color statusColor = Colors.orange;
                                      if (status == 'approved' || status == 'active' || status == 'repaid') {
                                        statusColor = Colors.green;
                                      } else if (status == 'denied' || status == 'rejected') {
                                        statusColor = Colors.red;
                                      }

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    lang.translate(purpose).toUpperCase(),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 15),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      status.toUpperCase(),
                                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 20),
                                              _loanRow(lang.translate('loan_amount_label'), 'TSh ${amount.toStringAsFixed(0)}'),
                                              _loanRow(lang.translate('loan_term_label'), '$term ${lang.locale == 'en' ? 'Months' : 'miezi'}'),
                                              _loanRow(lang.translate('loan_payment_label'), 'TSh ${monthly.toStringAsFixed(0)}'),
                                              _loanRow(lang.translate('loan_date_label'), dateStr),
                                            ],
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
                                    '${lang.translate('page_label')} $_currentPage / $totalPages',
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
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const DriverSubPageNavBar(type: 'loans', activeIndex: 2),
    );
  }

  Widget _loanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.gray, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy, fontSize: 13)),
        ],
      ),
    );
  }
}
