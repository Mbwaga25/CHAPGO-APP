import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/driver_subpage_navbar.dart';
import 'driver_widgets.dart';

class DriverScoreScreen extends StatefulWidget {
  const DriverScoreScreen({super.key});

  @override
  State<DriverScoreScreen> createState() => _DriverScoreScreenState();
}

class _DriverScoreScreenState extends State<DriverScoreScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _recalculating = false;

  // Score attributes
  double _score = 0;
  String _tier = 'new';
  bool _thinFile = true;
  int _daysActive = 0;
  int _totalScans = 0;
  double _avgDailyLiters = 0;
  double _avgDailyScans = 0;
  double _totalLiters = 0;
  double _totalSpentTsh = 0;

  Map<String, dynamic> _breakdown = {};
  Map<String, dynamic>? _eligibility;

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _loadScore();
  }

  Future<void> _loadScore({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final res = await _api.get('/scores/me');
      if (mounted) {
        setState(() {
          _score = _num(res['score']);
          _tier = (res['tier'] as String? ?? 'new').toLowerCase();
          _thinFile = res['thinFile'] as bool? ?? true;
          _daysActive = _num(res['days_active']).round();
          _totalScans = _num(res['total_scans']).round();
          _avgDailyLiters = _num(res['avg_daily_liters']);
          _avgDailyScans = _num(res['avg_daily_scans']);
          _totalLiters = _num(res['total_liters']);
          _totalSpentTsh = _num(res['total_spent_tsh']);
          _breakdown = (res['breakdown'] as Map?)?.cast<String, dynamic>() ?? {};
          _eligibility = res['loan_eligibility'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('score load error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch score data: $e'),
            backgroundColor: DriverDark.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _recalculateScore() async {
    setState(() => _recalculating = true);
    try {
      await _api.post('/scores/recalculate');
      if (mounted) {
        final lang = context.read<LanguageProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('score_recalculated_success')),
            backgroundColor: DriverDark.greenLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadScore(silent: true);
    } catch (e) {
      debugPrint('score recalculate error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh Boda Score: $e'),
            backgroundColor: DriverDark.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _recalculating = false);
      }
    }
  }

  String _getTierDesc(String tier, String locale) {
    final isSw = locale == 'sw';
    switch (tier.toLowerCase()) {
      case 'platinum':
        return isSw
            ? 'Kiwango cha Platinum: Unastahili mikopo mikubwa zaidi na riba ndogo ya upendeleo.'
            : 'Platinum Tier: Qualifies you for maximum loan limits and the lowest interest rates.';
      case 'gold':
        return isSw
            ? 'Kiwango cha Gold: Unastahili mikopo ya kati hadi mikubwa na viwango vya riba nafuu.'
            : 'Gold Tier: Qualifies you for medium-to-high loan limits with discounted interest rates.';
      case 'silver':
        return isSw
            ? 'Kiwango cha Silver: Unastahili mikopo ya kiwango cha kawaida na riba nafuu.'
            : 'Silver Tier: Qualifies you for standard loan limits with regular interest rates.';
      case 'bronze':
        return isSw
            ? 'Kiwango cha Bronze: Unastahili mikopo ya msingi ili kuanza safari yako ya kibiashara.'
            : 'Bronze Tier: Basic entry-level loan limit to start building your credit record.';
      default:
        return isSw
            ? 'Kiwango cha NEW: Alama zako bado zinahesabiwa. Endelea kuscan mafuta!'
            : 'NEW Tier: Your Boda Score is under calculation. Keep scanning fuel!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final tierColor = DriverDark.tierColor(_tier);
    final isSw = lang.locale == 'sw';

    return Scaffold(
      backgroundColor: DriverDark.dark,
      appBar: AppBar(
        backgroundColor: DriverDark.dark,
        foregroundColor: DriverDark.white,
        elevation: 0,
        title: Text(
          lang.translate('boda_score'),
          style: TextStyle(fontWeight: FontWeight.w700, color: DriverDark.white),
        ),
        actions: [
          _recalculating
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: DriverDark.gold),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: lang.translate('recalculate_score_btn'),
                  onPressed: _recalculateScore,
                ),
        ],
      ),
      bottomNavigationBar: const DriverSubPageNavBar(activeIndex: -1),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: DriverDark.gold))
          : RefreshIndicator(
              color: DriverDark.gold,
              backgroundColor: DriverDark.navy,
              onRefresh: () => _loadScore(silent: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                children: [
                  // Overview Narrative
                  Text(
                    lang.translate('boda_score_desc'),
                    style: TextStyle(fontSize: 13, color: DriverDark.grey, height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // Score dial card
                  DCard(
                    borderColor: tierColor.withValues(alpha: 0.25),
                    fill: DriverDark.navy,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            DScoreRing(
                              value: _score / 1000,
                              centerText: '${_score.round()}',
                              maxText: '/ 1000',
                              color: tierColor,
                              size: 110,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DBadge(
                                    text: _tier.toUpperCase(),
                                    color: tierColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getTierDesc(_tier, lang.locale),
                                    style: TextStyle(fontSize: 12, color: DriverDark.white, height: 1.4),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${lang.translate('days_active_short')}: $_daysActive · '
                                    '${lang.translate('scan_count_label')}: $_totalScans\n'
                                    '${lang.translate('daily_avg_scans')}: ${_avgDailyScans.toStringAsFixed(1)} · '
                                    'Liters: ${_avgDailyLiters.toStringAsFixed(1)}L',
                                    style: TextStyle(fontSize: 10, color: DriverDark.grey, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_eligibility != null) ...[
                          const SizedBox(height: 16),
                          const DRowDivider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.translate('eligible_loan_range'),
                                style: TextStyle(fontSize: 12, color: DriverDark.grey),
                              ),
                              Text(
                                '${_num(_eligibility!['min']).round()} — ${_num(_eligibility!['max']).round()} TSh',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DriverDark.gold),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        const DRowDivider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSw ? 'Jumla ya Lita / Matumizi' : 'Total Liters / Fuel Spent',
                              style: TextStyle(fontSize: 12, color: DriverDark.grey),
                            ),
                            Text(
                              '${_totalLiters.toStringAsFixed(1)}L · ${_totalSpentTsh.round()} TSh',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DriverDark.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thin-file Notice
                  if (_thinFile || _tier == 'new')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DCard(
                        borderColor: DriverDark.gold.withValues(alpha: 0.3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lang.translate('thin_file_note'),
                                style: TextStyle(fontSize: 12, color: DriverDark.greyLight, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Score Breakdown Section
                  DSectionHead(title: lang.translate('score_breakdown')),
                  DCard(
                    child: Column(
                      children: [
                        _buildComponentRow(
                          lang.translate('income_consistency_label'),
                          _num(_breakdown['income']).round(),
                          DriverDark.greenLight,
                        ),
                        const DRowDivider(),
                        _buildComponentRow(
                          lang.translate('attendance_regularity_label'),
                          _num(_breakdown['attendance']).round(),
                          DriverDark.gold,
                        ),
                        const DRowDivider(),
                        _buildComponentRow(
                          lang.translate('hours_discipline_label'),
                          _num(_breakdown['hours']).round(),
                          const Color(0xFF7FD4E0),
                        ),
                        const DRowDivider(),
                        _buildComponentRow(
                          lang.translate('fuel_efficiency_label'),
                          _num(_breakdown['efficiency']).round(),
                          DriverDark.greenLight,
                        ),
                        const DRowDivider(),
                        _buildComponentRow(
                          lang.translate('sacco_compliance_label'),
                          _num(_breakdown['sacco']).round(),
                          DriverDark.gold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Action Shortcuts
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/driver/cashflow');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DriverDark.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              lang.translate('btn_go_to_money'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/driver/saccos');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DriverDark.white,
                              side: BorderSide(color: DriverDark.cardBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              lang.translate('btn_go_to_saccos'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DriverDark.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // How to Improve Section
                  DSectionHead(title: lang.translate('boda_score_tips_title')),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      lang.translate('improve_score_hint'),
                      style: TextStyle(fontSize: 12, color: DriverDark.grey),
                    ),
                  ),

                  _buildTipCard(
                    '💰',
                    lang.translate('tip_income_title'),
                    lang.translate('tip_income_desc'),
                    DriverDark.greenLight,
                  ),
                  _buildTipCard(
                    '⛽',
                    lang.translate('tip_attendance_title'),
                    lang.translate('tip_attendance_desc'),
                    DriverDark.gold,
                  ),
                  _buildTipCard(
                    '⏰',
                    lang.translate('tip_hours_title'),
                    lang.translate('tip_hours_desc'),
                    const Color(0xFF7FD4E0),
                  ),
                  _buildTipCard(
                    '🌱',
                    lang.translate('tip_efficiency_title'),
                    lang.translate('tip_efficiency_desc'),
                    DriverDark.greenLight,
                  ),
                  _buildTipCard(
                    '🏛️',
                    lang.translate('tip_sacco_title'),
                    lang.translate('tip_sacco_desc'),
                    DriverDark.gold,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildComponentRow(String label, int points, Color color) {
    final pct = points / 200.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DriverDark.white),
              ),
              Text(
                '$points / 200',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DProgressBar(value: pct, color: color, height: 6),
        ],
      ),
    );
  }

  Widget _buildTipCard(String emoji, String title, String description, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DCard(
        borderColor: DriverDark.cardBorder,
        fill: DriverDark.navy,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DriverDark.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: DriverDark.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
