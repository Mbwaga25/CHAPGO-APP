import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';

class SaccoDriverDetailScreen extends StatefulWidget {
  final String driverId;
  const SaccoDriverDetailScreen({super.key, required this.driverId});

  @override
  State<SaccoDriverDetailScreen> createState() => _SaccoDriverDetailScreenState();
}

class _SaccoDriverDetailScreenState extends State<SaccoDriverDetailScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _data;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/sacco/drivers/${widget.driverId}/details');
      setState(() {
        _data = res;
      });
    } catch (e) {
      _showSnackbar(e.toString(), Colors.red);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _sendLoanInvitation() async {
    try {
      await _api.post('/sacco/drivers/${widget.driverId}/invite');
      _showSnackbar('Loan invitation sent to driver!', Colors.green);
    } catch (e) {
      _showSnackbar(e.toString(), Colors.red);
    }
  }

  Future<void> _recruitDriver(LanguageProvider lang) async {
    final contributionController = TextEditingController(text: '10000');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lang.locale == 'en' ? 'Add Driver to Sacco' : 'Sajili Dereva kwenye Sacco'),
          content: TextField(
            controller: contributionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: lang.locale == 'en' ? 'Monthly Contribution (TSh)' : 'Michango kwa Mwezi (TSh)',
              prefixText: 'TSh ',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.locale == 'en' ? 'Cancel' : 'Ghairi')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(contributionController.text.trim()) ?? 0.0;
                if (amt <= 0) {
                  _showSnackbar('Invalid contribution amount', Colors.red);
                  return;
                }
                try {
                  await _api.post('/sacco/members', body: {
                    'driver_id': widget.driverId,
                    'monthly_contribution_tsh': amt,
                  });
                  Navigator.pop(context);
                  _showSnackbar('Driver recruited successfully!', Colors.green);
                  _loadDetails();
                } catch (e) {
                  _showSnackbar(e.toString(), Colors.red);
                }
              },
              child: Text(lang.locale == 'en' ? 'Confirm' : 'Thibitisha'),
            ),
          ],
        );
      },
    );
  }

  void _recordRepaymentDialog(LanguageProvider lang, Map<String, dynamic> loan) {
    final remaining = double.parse(loan['remaining_balance'].toString());
    final amountController = TextEditingController(text: remaining > 0 ? remaining.toStringAsFixed(0) : '');
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedMethod = 'cash';
    bool saving = false;

    final methods = [
      {'val': 'cash', 'label': 'Cash / Fedha taslimu'},
      {'val': 'mpesa', 'label': 'M-Pesa'},
      {'val': 'mixx', 'label': 'Tigo Pesa / Mixx'},
      {'val': 'airtel_money', 'label': 'Airtel Money'},
      {'val': 'chapesa', 'label': 'ChaPesa'},
      {'val': 'bank', 'label': 'Bank Transfer / Benki'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final enteredAmt = double.tryParse(amountController.text.trim()) ?? 0.0;
            final isOverpayment = enteredAmt > remaining && remaining > 0;

            return AlertDialog(
              title: Text(lang.translate('record_repayment') ?? 'Record Loan Repayment'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${lang.translate("remaining_balance")}: TSh ${remaining.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: lang.translate('repayment_amount') ?? 'Repayment Amount',
                          prefixText: 'TSh ',
                          helperText: '${lang.locale == "en" ? "Remaining" : "Imebaki"}: TSh ${remaining.toStringAsFixed(0)}',
                          helperStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isOverpayment) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lang.locale == 'en'
                                      ? 'Amount exceeds remaining balance (TSh ${remaining.toStringAsFixed(0)})'
                                      : 'Kiasi kinazidi salio lililobaki (TSh ${remaining.toStringAsFixed(0)})',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: InputDecoration(
                          labelText: lang.translate('repayment_method') ?? 'Payment Method',
                        ),
                        items: methods.map((m) {
                          return DropdownMenuItem<String>(
                            value: m['val'],
                            child: Text(m['label']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedMethod = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference ID / Receipt (Optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.locale == 'en' ? 'Cancel' : 'Ghairi')),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            _showSnackbar('Please enter a valid amount', Colors.red);
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            await _api.post('/sacco/loans/${loan["id"]}/repayments', body: {
                              'amount_tsh': amt,
                              'repayment_method': selectedMethod,
                              'reference': referenceController.text.trim(),
                              'notes': notesController.text.trim(),
                            });
                            Navigator.pop(context);
                            _showSnackbar(
                              lang.translate('repayment_success') ?? 'Repayment recorded successfully!',
                              Colors.green,
                            );
                            _loadDetails();
                          } catch (e) {
                            _showSnackbar(e.toString(), Colors.red);
                          } finally {
                            setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(lang.locale == 'en' ? 'Confirm' : 'Thibitisha'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    if (_loading || _data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final driver = _data!['driver'] ?? {};
    final account = _data!['saccoAccount'];
    final cashflowSummary = _data!['cashflowSummary'] ?? {};
    final cashflow = _data!['cashflow'] as List? ?? [];
    final loans = _data!['loans'] as List? ?? [];

    final score = (driver['score'] as num?)?.toDouble() ?? 0.0;
    final tier = driver['tier'] as String? ?? 'unranked';
    final hasSacco = account != null;

    // Separate income and expense
    final incomeList = cashflow.where((c) => c['type'] == 'income').toList();
    final expenseList = cashflow.where((c) => c['type'] == 'expense').toList();

    final totalIncome = double.tryParse(cashflowSummary['totalIncome']?.toString() ?? '0') ?? 0.0;
    final totalExpense = double.tryParse(cashflowSummary['totalExpense']?.toString() ?? '0') ?? 0.0;
    final netBalance = double.tryParse(cashflowSummary['netBalance']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(driver['full_name'] ?? 'Driver Profile'),
      ),
      body: Column(
        children: [
          // Fixed top section: Profile + Sacco Membership + Summary chips
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile & Credit Score Header Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.gold,
                          child: Text(
                            driver['full_name'] != null ? driver['full_name'][0].toUpperCase() : 'D',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver['full_name'] ?? '',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
                              ),
                              const SizedBox(height: 4),
                              Text('${driver['phone']} | ${driver['vehicle_plate'] ?? ""}', style: const TextStyle(color: AppTheme.gray)),
                              const SizedBox(height: 4),
                              Text(
                                'Score: ${score.toStringAsFixed(0)} (${tier.toUpperCase()})',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Sacco Membership Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: hasSacco
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${lang.locale == "en" ? "Account No" : "Akaunti"}: ${account["account_number"]}'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      account['contribution_status'].toString().toUpperCase(),
                                      style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${lang.locale == "en" ? "Savings" : "Akiba"}: TSh ${double.parse(account["balance_tsh"].toString()).toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  Text(
                                    '${lang.locale == "en" ? "Contribution" : "Michango"}: TSh ${double.parse(account["monthly_contribution_tsh"].toString()).toStringAsFixed(0)}/m',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Text(
                                lang.locale == 'en'
                                    ? 'This driver is not a member of your Sacco.'
                                    : 'Dereva huyu sio mwanachama wa Sacco yako.',
                                style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.gray),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _recruitDriver(lang),
                                  icon: const Icon(Icons.person_add),
                                  label: Text(lang.translate('recruit_driver') ?? 'Add as Sacco Member'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Summary chips row
                Row(
                  children: [
                    _buildSummaryChip(
                      icon: Icons.arrow_upward,
                      label: lang.locale == 'en' ? 'Income' : 'Mapato',
                      value: 'TSh ${totalIncome.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildSummaryChip(
                      icon: Icons.arrow_downward,
                      label: lang.locale == 'en' ? 'Expense' : 'Matumizi',
                      value: 'TSh ${totalExpense.toStringAsFixed(0)}',
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _buildSummaryChip(
                      icon: Icons.account_balance_wallet,
                      label: lang.locale == 'en' ? 'Net' : 'Jumla',
                      value: 'TSh ${netBalance.toStringAsFixed(0)}',
                      color: netBalance >= 0 ? Colors.blue : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.navy,
              unselectedLabelColor: AppTheme.gray,
              indicatorColor: AppTheme.gold,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  text: '${lang.locale == "en" ? "Income" : "Mapato"} (${incomeList.length})',
                ),
                Tab(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  text: '${lang.locale == "en" ? "Expense" : "Matumizi"} (${expenseList.length})',
                ),
                Tab(
                  icon: const Icon(Icons.account_balance, size: 18),
                  text: '${lang.locale == "en" ? "Loans" : "Mikopo"} (${loans.length})',
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Income
                _buildCashflowList(lang, incomeList, isIncome: true),

                // Tab 2: Expense
                _buildCashflowList(lang, expenseList, isIncome: false),

                // Tab 3: Loans
                _buildLoansTab(lang, loans),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashflowList(LanguageProvider lang, List<dynamic> items, {required bool isIncome}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncome ? Icons.trending_up : Icons.trending_down,
                size: 48,
                color: AppTheme.grayLight,
              ),
              const SizedBox(height: 12),
              Text(
                isIncome
                    ? (lang.locale == 'en' ? 'No income records found.' : 'Hakuna rekodi za mapato.')
                    : (lang.locale == 'en' ? 'No expense records found.' : 'Hakuna rekodi za matumizi.'),
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.gray),
              ),
            ],
          ),
        ),
      );
    }

    // Group by date
    final Map<String, List<dynamic>> grouped = {};
    for (final item in items) {
      final dateStr = item['date']?.toString();
      final dateKey = dateStr != null && dateStr.length >= 10 ? dateStr.substring(0, 10) : 'Unknown';
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(item);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadDetails,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sortedDates.length,
        itemBuilder: (context, i) {
          final date = sortedDates[i];
          final dayItems = grouped[date]!;
          final dayTotal = dayItems.fold<double>(0.0, (sum, c) => sum + (double.tryParse(c['amount'].toString()) ?? 0.0));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        date,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navy),
                      ),
                    ),
                    Text(
                      '${isIncome ? "+" : "-"} TSh ${dayTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Items for this date
              ...dayItems.map((c) {
                final amt = double.tryParse(c['amount'].toString()) ?? 0.0;
                final category = (c['category'] ?? '').toString().toUpperCase();
                final description = c['description'] ?? '';
                final time = c['date']?.toString();
                final timeStr = time != null && time.length >= 16 ? time.substring(11, 16) : '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: 0.5,
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      description.isEmpty ? timeStr : '$description • $timeStr',
                      style: const TextStyle(fontSize: 11, color: AppTheme.gray),
                    ),
                    trailing: Text(
                      '${isIncome ? "+" : "-"} TSh ${amt.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              }),
              if (i < sortedDates.length - 1)
                Divider(height: 16, color: Colors.grey.shade200),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoansTab(LanguageProvider lang, List<dynamic> loans) {
    if (loans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance, size: 48, color: AppTheme.grayLight),
              const SizedBox(height: 12),
              Text(
                lang.translate('no_active_loans') ?? 'No loans recorded.',
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.gray),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _sendLoanInvitation,
                icon: const Icon(Icons.send, size: 18),
                label: Text(lang.translate('invite_driver_loan') ?? 'Send Loan Invitation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.gold,
                  side: const BorderSide(color: AppTheme.gold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length + 1, // +1 for the invite button at the bottom
      itemBuilder: (context, idx) {
        if (idx == loans.length) {
          // Invite button at bottom
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _sendLoanInvitation,
                icon: const Icon(Icons.send),
                label: Text(lang.translate('invite_driver_loan') ?? 'Send Loan Invitation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.gold,
                  side: const BorderSide(color: AppTheme.gold),
                ),
              ),
            ),
          );
        }

        final loan = loans[idx];
        final amt = double.parse(loan['amount_tsh'].toString());
        final totalRepaid = double.tryParse((loan['total_repaid'] ?? '0').toString()) ?? 0.0;
        final bal = double.parse(loan['remaining_balance'].toString());
        final isRepaid = loan['status'] == 'repaid';
        final isPending = loan['status'] == 'pending';
        final isActive = loan['status'] == 'approved' || loan['status'] == 'active' || loan['status'] == 'disbursed';
        final repaymentPercent = amt > 0 ? (totalRepaid / amt).clamp(0.0, 1.0) : 0.0;

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
                      '${loan["loan_purpose"].toString().toUpperCase()} LOAN',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRepaid
                            ? Colors.green.shade50
                            : isPending
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        loan['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: isRepaid
                              ? Colors.green.shade800
                              : isPending
                                  ? Colors.orange.shade800
                                  : Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${lang.translate("loan_amount_label")}: TSh ${amt.toStringAsFixed(0)}'),
                    Text(
                      '${lang.translate("remaining_balance")}: TSh ${bal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bal > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                if (isActive || isRepaid) ...[
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: repaymentPercent,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isRepaid ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(repaymentPercent * 100).toStringAsFixed(0)}% ${lang.locale == "en" ? "repaid" : "amelipa"}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                if (isActive) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _recordRepaymentDialog(lang, loan),
                      icon: const Icon(Icons.payments),
                      label: Text(lang.translate('record_repayment') ?? 'Record Repayment'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
