import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';

class SaccoLoanDetailScreen extends StatefulWidget {
  final String loanId;
  const SaccoLoanDetailScreen({super.key, required this.loanId});

  @override
  State<SaccoLoanDetailScreen> createState() => _SaccoLoanDetailScreenState();
}

class _SaccoLoanDetailScreenState extends State<SaccoLoanDetailScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _loadingRepayments = true;
  Map<String, dynamic>? _loan;
  List<dynamic> _repayments = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadLoanDetails(),
      _loadRepayments(),
    ]);
  }

  Future<void> _loadLoanDetails() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/sacco/loans/${widget.loanId}');
      setState(() {
        _loan = res;
      });
    } catch (e) {
      _showSnackbar(e.toString(), Colors.red);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRepayments() async {
    setState(() => _loadingRepayments = true);
    try {
      final res = await _api.get('/sacco/loans/${widget.loanId}/repayments');
      setState(() {
        _repayments = res['repayments'] ?? [];
      });
    } catch (e) {
      debugPrint('Failed to load repayments: $e');
    } finally {
      setState(() => _loadingRepayments = false);
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

  Future<void> _updateMissedCount(String action) async {
    try {
      final res = await _api.post('/sacco/loans/${widget.loanId}/missed', body: {
        'action': action,
      });
      if (res['success'] == true) {
        setState(() {
          if (_loan != null) {
            _loan!['missed_payments_count'] = res['missed_payments_count'];
          }
        });
        _showSnackbar('Missed payments count updated!', Colors.green);
      }
    } catch (e) {
      _showSnackbar(e.toString(), Colors.red);
    }
  }

  void _recordRepaymentDialog(LanguageProvider lang) {
    if (_loan == null) return;
    final amountController = TextEditingController();
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
            return AlertDialog(
              title: Text(lang.translate('record_repayment')),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${lang.translate("remaining_balance")}: TSh ${double.parse(_loan!["remaining_balance"].toString()).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.translate('repayment_amount'),
                          prefixText: 'TSh ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: InputDecoration(
                          labelText: lang.translate('repayment_method'),
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
                            await _api.post('/sacco/loans/${widget.loanId}/repayments', body: {
                              'amount_tsh': amt,
                              'repayment_method': selectedMethod,
                              'reference': referenceController.text.trim(),
                              'notes': notesController.text.trim(),
                            });
                            Navigator.pop(context);
                            _showSnackbar(lang.translate('repayment_success'), Colors.green);
                            _loadAllData();
                          } catch (e) {
                            _showSnackbar(e.toString(), Colors.red);
                          } finally {
                            setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(lang.locale == 'en' ? 'Confirm' : 'Thibitisha'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _loanDecisionDialog(String decision, LanguageProvider lang) {
    final notesController = TextEditingController();
    final isApprove = decision == 'approved';
    bool submitting = false;

    final amountController = TextEditingController(
      text: _loan != null ? double.parse(_loan!['amount_tsh'].toString()).toStringAsFixed(0) : '',
    );
    final termController = TextEditingController(
      text: _loan != null ? _loan!['term_months'].toString() : '',
    );
    String selectedFrequency = _loan != null ? (_loan!['repayment_frequency'] ?? 'monthly') : 'monthly';
    final customDaysController = TextEditingController(
      text: _loan != null && _loan!['repayment_frequency_custom_days'] != null
          ? _loan!['repayment_frequency_custom_days'].toString()
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isApprove
                    ? (lang.locale == 'en' ? 'Confirm Loan Approval' : 'Thibitisha Kukubali Mkopo')
                    : (lang.locale == 'en' ? 'Confirm Loan Rejection' : 'Thibitisha Kukataa Mkopo'),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isApprove
                            ? (lang.locale == 'en'
                                ? 'Are you sure you want to approve this loan application?'
                                : 'Je, una uhakika unataka kukubali ombi hili la mkopo?')
                            : (lang.locale == 'en'
                                ? 'Are you sure you want to reject this loan application?'
                                : 'Je, una uhakika unataka kukataa ombi hili la mkopo?'),
                        style: const TextStyle(fontSize: 14, color: AppTheme.navy),
                      ),
                      const SizedBox(height: 16),
                      if (isApprove) ...[
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.locale == 'en' ? 'Approved Amount (TSh)' : 'Kiasi Kilichokubaliwa (TSh)',
                            prefixText: 'TSh ',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: termController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.locale == 'en' ? 'Term (Months)' : 'Muda wa Mkopo (Miezi)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedFrequency,
                          decoration: InputDecoration(
                            labelText: lang.locale == 'en' ? 'Repayment Frequency' : 'Mzunguko wa Malipo',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily / Kila Siku')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly / Kila Wiki')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly / Kila Mwezi')),
                            DropdownMenuItem(value: 'custom', child: Text('Custom Days / Siku Maalum')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedFrequency = val;
                              });
                            }
                          },
                        ),
                        if (selectedFrequency == 'custom') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: customDaysController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.locale == 'en' ? 'Custom Days Interval' : 'Muda wa Siku Maalum',
                              hintText: 'e.g. 5',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: lang.locale == 'en' ? 'Decision Notes (Optional)' : 'Maelezo ya Uamuzi (Si Lazima)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.locale == 'en' ? 'Cancel' : 'Ghairi'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final Map<String, dynamic> body = {
                            'decision': decision,
                            'notes': notesController.text.trim(),
                          };
                          if (isApprove) {
                            final approvedAmount = double.tryParse(amountController.text.trim());
                            final termMonths = int.tryParse(termController.text.trim());
                            if (approvedAmount == null || approvedAmount <= 0) {
                              _showSnackbar(
                                lang.locale == 'en' ? 'Please enter a valid approved amount' : 'Tafadhali weka kiasi sahihi kilichokubaliwa',
                                Colors.red,
                              );
                              return;
                            }
                            body['approved_amount_tsh'] = approvedAmount;
                            if (termMonths != null) {
                              body['term_months'] = termMonths;
                            }
                            body['repayment_frequency'] = selectedFrequency;
                            if (selectedFrequency == 'custom') {
                              final customDays = int.tryParse(customDaysController.text.trim());
                              if (customDays == null || customDays <= 0) {
                                _showSnackbar(
                                  lang.locale == 'en' ? 'Please enter custom days interval' : 'Tafadhali weka muda sahihi wa siku maalum',
                                  Colors.red,
                                );
                                  return;
                              }
                              body['repayment_frequency_custom_days'] = customDays;
                            }
                          }

                          setDialogState(() => submitting = true);
                          try {
                            await _api.post('/loans/${widget.loanId}/decide', body: body);
                            Navigator.pop(context);
                            _showSnackbar(
                              isApprove
                                  ? (lang.locale == 'en' ? 'Loan application approved!' : 'Ombi la mkopo limekubaliwa!')
                                  : (lang.locale == 'en' ? 'Loan application rejected!' : 'Ombi la mkopo limekataliwa!'),
                              isApprove ? Colors.green : Colors.red,
                            );
                            _loadAllData();
                          } catch (e) {
                            _showSnackbar(e.toString(), Colors.red);
                          } finally {
                            setDialogState(() => submitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.green : Colors.red),
                  child: submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(lang.locale == 'en' ? 'Confirm' : 'Thibitisha'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'active':
        return Colors.green;
      case 'repaid':
        return Colors.blue;
      case 'denied':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getFrequencyLabel(String freq, int? customDays, LanguageProvider lang) {
    if (freq == 'custom') {
      final label = lang.translate('custom');
      final days = customDays ?? 0;
      return '$label ($days ${lang.translate("days_label")})';
    }
    return lang.translate(freq);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    if (_loading || _loan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.locale == 'en' ? 'Loan Details' : 'Maelezo ya Mkopo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final driverName = _loan!['driver_name'] ?? 'Driver';
    final chapgoId = _loan!['chapgo_id'] ?? '';
    final phone = _loan!['driver_phone'] ?? '';
    final score = double.tryParse(_loan!['score']?.toString() ?? '') ?? 0.0;
    final tier = _loan!['tier'] as String? ?? 'unranked';

    final amount = double.parse(_loan!['amount_tsh'].toString());
    final repaid = double.parse(_loan!['total_repaid'].toString());
    final balance = double.parse(_loan!['remaining_balance'].toString());
    final term = _loan!['term_months'] ?? 3;
    final monthly = double.parse(_loan!['monthly_payment_tsh'].toString());
    final purpose = _loan!['loan_purpose'] ?? '';
    final frequency = _loan!['repayment_frequency'] ?? 'monthly';
    final customDays = _loan!['repayment_frequency_custom_days'] as int?;
    final status = _loan!['status'] ?? 'pending';
    final date = _loan!['applied_at'] != null ? _loan!['applied_at'].toString().substring(0, 10) : '';
    final missedCount = _loan!['missed_payments_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.locale == 'en' ? 'Loan Details' : 'Maelezo ya Mkopo'),
        backgroundColor: AppTheme.navy,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Borrower Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navy),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.navy, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              chapgoId,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${lang.locale == "en" ? "Phone" : "Simu"}: $phone', style: const TextStyle(color: AppTheme.gray)),
                          Text(
                            '${lang.translate("boda_score")}: ${score.toStringAsFixed(0)} (${tier.toUpperCase()})',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Loan Specs Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Spec / Maelezo',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toString().toUpperCase(),
                              style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _specRow(lang.translate('loan_purpose_label'), purpose.toUpperCase()),
                      _specRow(lang.translate('loan_amount_label'), 'TSh ${amount.toStringAsFixed(0)}'),
                      _specRow(lang.translate('total_repaid'), 'TSh ${repaid.toStringAsFixed(0)}', color: Colors.green),
                      _specRow(lang.translate('remaining_balance'), 'TSh ${balance.toStringAsFixed(0)}', color: Colors.red, isBold: true),
                      _specRow(lang.translate('repayment_frequency'), _getFrequencyLabel(frequency, customDays, lang)),
                      _specRow(lang.translate('loan_term_label'), '$term ${lang.locale == "en" ? "Months" : "miezi"}'),
                      _specRow(lang.translate('loan_payment_label'), 'TSh ${monthly.toStringAsFixed(0)}'),
                      _specRow(lang.translate('loan_date_label'), date),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Missed Payments Counter Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate('missed_payments'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (missedCount > 0)
                                const Icon(Icons.warning, color: Colors.red, size: 18),
                              if (missedCount > 0) const SizedBox(width: 4),
                              Text(
                                '$missedCount ${lang.translate("days_label").toLowerCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: missedCount > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 30),
                            onPressed: () => _updateMissedCount('decrement'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.red, size: 30),
                            onPressed: () => _updateMissedCount('increment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Repayments Log Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('history_repayment'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                      ),
                      const Divider(height: 24),
                      if (_loadingRepayments)
                        const Center(child: CircularProgressIndicator())
                      else if (_repayments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              lang.locale == 'en' ? 'No repayment logs found.' : 'Hakuna historia ya marejesho.',
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _repayments.length,
                          itemBuilder: (context, idx) {
                            final r = _repayments[idx];
                            final rAmt = double.parse(r['amount'].toString());
                            final rMethod = r['repayment_method'] ?? 'cash';
                            final rDate = r['date'] != null ? r['date'].toString().substring(0, 16) : '';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.greenAccent,
                                radius: 16,
                                child: Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                              title: Text(
                                'TSh ${rAmt.toStringAsFixed(0)} via ${rMethod.toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(rDate),
                              trailing: r['reference'] != null ? Text(r['reference']) : null,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Record Repayment Button or Decision Buttons
              if (status.toLowerCase() == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _loanDecisionDialog('denied', lang),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(lang.locale == 'en' ? 'Reject' : 'Kataa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _loanDecisionDialog('approved', lang),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(lang.locale == 'en' ? 'Approve' : 'Kukubali'),
                      ),
                    ),
                  ],
                ),
              ] else if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'active') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _recordRepaymentDialog(lang),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(lang.translate('record_repayment')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _specRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.gray)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}
