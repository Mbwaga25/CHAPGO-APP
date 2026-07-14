import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/cashflow_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/driver_subpage_navbar.dart';

class DriverEvaluationReportScreen extends StatefulWidget {
  const DriverEvaluationReportScreen({super.key});

  @override
  State<DriverEvaluationReportScreen> createState() => _DriverEvaluationReportScreenState();
}

class _DriverEvaluationReportScreenState extends State<DriverEvaluationReportScreen> {
  final _api = ApiService();
  bool _loading = true;
  double _score = 0;
  String _tier = 'unranked';
  int _scansCount = 0;
  int _daysActive = 0;
  Map<String, dynamic>? _eligibility;
  String _reportDateFilter = 'monthly'; // Default: Monthly

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

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _loading = true);
    try {
      final scoreRes = await _api.get('/scores/me');
      setState(() {
        _score = double.tryParse(scoreRes['score']?.toString() ?? '') ?? 0.0;
        _tier = scoreRes['tier'] as String? ?? 'unranked';
        _scansCount = scoreRes['total_scans'] as int? ?? 0;
        _daysActive = scoreRes['days_active'] as int? ?? 0;
        _eligibility = scoreRes['loan_eligibility'] as Map<String, dynamic>?;
      });
    } catch (e) {
      debugPrint('Failed to load score/report: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final cashflow = context.watch<CashflowProvider>();

    // Compute System Usage / Utilization Score (0 - 100) based on filtered date range
    final filteredTxs = cashflow.transactions.where((t) => _isTxInDateRange(t.date, _reportDateFilter)).toList();
    final txCount = filteredTxs.length;
    final double displayIncome = filteredTxs.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final double displayExpense = filteredTxs.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
    final double netBalance = displayIncome - displayExpense;

    final double usageRating = ((_scansCount.clamp(0, 30) * 1.5) + (txCount.clamp(0, 20) * 2.5) + (_daysActive * 0.5)).clamp(10, 100);

    Color tierColor;
    switch (_tier.toLowerCase()) {
      case 'platinum':
        tierColor = Colors.teal;
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

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('menu_report'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Date range preset filter selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.translate('filter_date') ?? 'Date Filter / Kuchuja kwa Tarehe',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 14),
                      ),
                      DropdownButton<String>(
                        value: _reportDateFilter,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _reportDateFilter = val;
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
                  const SizedBox(height: 16),

                  // 1. Visual System Utilization Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate('eval_usage_score') ?? 'System Utilization Score',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: CircularProgressIndicator(
                                    value: usageRating / 100.0,
                                    strokeWidth: 10,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(usageRating > 70 ? Colors.green : (usageRating > 40 ? Colors.orange : Colors.red)),
                                  ),
                                ),
                                Text(
                                  '${usageRating.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.navy),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang.translate('eval_usage_desc') ?? 'Your rating of how actively you scan fuel and log cashflow. High usage improves credit tier!',
                            style: TextStyle(fontSize: 13, color: AppTheme.gray),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Financial Summary Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Summary / Muhtasari wa Fedha',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.translate('income'), style: TextStyle(color: AppTheme.gray)),
                              Text('TSh ${displayIncome.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.translate('expenses'), style: TextStyle(color: AppTheme.gray)),
                              Text('TSh ${displayExpense.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.translate('net_balance'), style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                              Text(
                                'TSh ${netBalance.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: netBalance >= 0 ? Colors.green : Colors.red, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Current Score & Tier Card
                  Card(
                    elevation: 2,
                    color: tierColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lang.translate('boda_score')}: ${_score.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lang.translate('credit_limit') ?? 'Current Tier'}: ${_tier.toUpperCase()}',
                            style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                          const Divider(color: Colors.white30, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${lang.translate('days_active_label')}:', style: const TextStyle(color: Colors.white70)),
                              Text('$_daysActive days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${lang.translate('scan_history_label')}:', style: const TextStyle(color: Colors.white70)),
                              Text('$_scansCount scans', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Qualification Tips
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate('eval_credit_tips') ?? 'Loan Qualification Tips',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navy),
                          ),
                          const SizedBox(height: 12),
                          _bulletTip(lang.translate('eval_tip_1') ?? 'Scan your QR code for every fuel fill to log activity.'),
                          _bulletTip(lang.translate('eval_tip_2') ?? 'Keep your cashflow records updated daily for better credit limits.'),
                          _bulletTip(lang.translate('eval_tip_3') ?? 'Maintain repayments to your SACCO to unlock Gold and Platinum tiers.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: const DriverSubPageNavBar(activeIndex: -1),
    );
  }

  Widget _bulletTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, size: 16, color: AppTheme.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppTheme.navy),
            ),
          ),
        ],
      ),
    );
  }
}
