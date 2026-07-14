import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/driver_subpage_navbar.dart';

/// Driver SACCO hub: shows the SACCO the rider has joined, lets them browse
/// other SACCOs and send a join request, and view their loans + repayments
/// (and any late penalty) within their SACCO.
class DriverSaccosScreen extends StatefulWidget {
  const DriverSaccosScreen({super.key});

  @override
  State<DriverSaccosScreen> createState() => _DriverSaccosScreenState();
}

class _DriverSaccosScreenState extends State<DriverSaccosScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _saccos = [];
  List<dynamic> _loans = [];
  List<dynamic> _akiba = [];
  final Set<String> _requesting = {};
  final Set<String> _expandedSaccos = {};
  final Map<String, List<dynamic>> _saccoMichango = {};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _api.setToken(user.token);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _toggleSaccoExpand(String saccoId) {
    setState(() {
      if (_expandedSaccos.contains(saccoId)) {
        _expandedSaccos.remove(saccoId);
      } else {
        _expandedSaccos.add(saccoId);
        _loadSaccoMichango(saccoId);
      }
    });
  }

  Future<void> _loadSaccoMichango(String saccoId) async {
    try {
      final r = await _api.get('/driver/sacco/michango-plans?sacco_id=$saccoId');
      final plans = r['plans'] as List? ?? [];
      if (mounted) {
        setState(() {
          _saccoMichango[saccoId] = plans;
        });
      }
    } catch (e) {
      debugPrint('Failed to load michango for $saccoId: $e');
    }
  }

  num _num(dynamic v) => v == null ? 0 : (v is num ? v : (num.tryParse(v.toString()) ?? 0));

  String _fmt(num v) {
    final s = v.round().toString();
    return 'TSh ${s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/driver/saccos');
      _saccos = r['saccos'] as List? ?? [];
    } catch (e) {
      debugPrint('saccos: $e');
    }
    try {
      final r = await _api.get('/loans/me');
      _loans = r['loans'] as List? ?? [];
    } catch (e) {
      debugPrint('loans: $e');
    }
    // Load savings accounts across all SACCOs.
    try {
      final r = await _api.get('/driver/sacco/akiba-accounts');
      _akiba = r['accounts'] as List? ?? [];
    } catch (e) {
      debugPrint('akiba: $e');
    }
    // Reload dynamic plan details for currently expanded cards
    _saccoMichango.clear();
    for (final saccoId in _expandedSaccos) {
      await _loadSaccoMichango(saccoId);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _requestJoin(String saccoId, String saccoName, LanguageProvider lang) async {
    setState(() => _requesting.add(saccoId));
    try {
      final res = await _api.post('/driver/saccos/$saccoId/join-request');
      final msg = lang.locale == 'sw'
          ? (res['message_sw'] ?? res['message'] ?? 'Ombi limetumwa')
          : (res['message'] ?? 'Request sent');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.toString()), backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _requesting.remove(saccoId));
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    context.watch<ThemeProvider>();
    final en = lang.locale == 'en';
    
    final joinedSaccos = _saccos.where((s) => s['sacco_account_id'] != null).toList();
    final otherSaccos = _saccos.where((s) => s['sacco_account_id'] == null).toList();

    return Scaffold(
      appBar: AppBar(title: Text(en ? 'My SACCOs' : 'SACCO Zangu')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── My SACCOs ───────────────────────────────
                  _sectionTitle(en ? 'My SACCOs' : 'SACCO Zangu', Icons.verified),
                  const SizedBox(height: 8),
                  if (joinedSaccos.isEmpty)
                    _emptyCard(en
                        ? 'You have not joined any SACCO yet. Browse SACCOs below and send a join request.'
                        : 'Bado hujajiunga na SACCO yoyote. Vinjari SACCO hapa chini na utume ombi la kujiunga.')
                  else
                    ...joinedSaccos.map((sacco) {
                      final saccoId = sacco['id'] as String;
                      final saccoName = sacco['name'] as String? ?? 'SACCO';
                      final accountNum = sacco['account_number'] as String? ?? '';
                      final balance = _num(sacco['balance_tsh']);
                      final isExpanded = _expandedSaccos.contains(saccoId);
                      
                      final saccoAkiba = _akiba.where((a) => a['sacco_id'] == saccoId).toList();
                      final saccoMichango = _saccoMichango[saccoId] ?? [];
                      final saccoLoans = _loans.where((l) => l['sacco_id'] == saccoId).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isExpanded 
                                ? AppTheme.green.withValues(alpha: 0.5) 
                                : AppTheme.border,
                            width: isExpanded ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _toggleSaccoExpand(saccoId),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Text('🏛️', style: TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            saccoName,
                                            style: TextStyle(
                                              fontSize: 16, 
                                              fontWeight: FontWeight.w700, 
                                              color: AppTheme.navy,
                                            ),
                                          ),
                                          if (accountNum.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${en ? "Acc No" : "Namba ya Akaunti"}: $accountNum',
                                              style: TextStyle(fontSize: 12, color: AppTheme.gray),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.green.withValues(alpha: 0.12), 
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        en ? 'Member' : 'Mwanachama',
                                        style: TextStyle(
                                          fontSize: 11, 
                                          fontWeight: FontWeight.w700, 
                                          color: AppTheme.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isExpanded ? Icons.expand_less : Icons.expand_more, 
                                      color: AppTheme.gray,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            if (isExpanded) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          en ? 'Savings Balance' : 'Akiba Yako', 
                                          style: TextStyle(color: AppTheme.gray, fontSize: 13),
                                        ),
                                        Text(
                                          _fmt(balance),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800, 
                                            color: AppTheme.green, 
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    
                                    // ─── Akiba (savings accounts) ──────────────
                                    _akibaSection(en, lang, saccoId, saccoAkiba),
                                    const SizedBox(height: 16),
                                    
                                    // ─── Michango (contribution plans) ─────────
                                    _michangoSection(en, lang, saccoId, saccoMichango),
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          en ? 'Loans in this SACCO' : 'Mikopo kwenye SACCO hii',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => Navigator.pushNamed(
                                            context, 
                                            '/driver/loans',
                                            arguments: {
                                              'sacco_id': saccoId,
                                              'sacco_name': saccoName,
                                            },
                                          ).then((_) => _load()),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: Text(en ? 'Apply' : 'Omba'),
                                          style: TextButton.styleFrom(foregroundColor: AppTheme.navy),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (saccoLoans.isEmpty)
                                      _emptyCard(en ? 'No loans in this SACCO yet.' : 'Bado hakuna mikopo kwenye SACCO hii.')
                                    else
                                      ...saccoLoans.map((l) => _LoanCard(api: _api, loan: l as Map<String, dynamic>, lang: lang)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 22),

                  // ─── Other SACCOs ───────────────────────────
                  _sectionTitle(en ? 'Other SACCOs' : 'SACCO Nyingine', Icons.travel_explore),
                  const SizedBox(height: 8),
                  if (otherSaccos.isEmpty)
                    _emptyCard(en ? 'No other SACCOs available.' : 'Hakuna SACCO nyingine zilizopo.')
                  else
                    ...otherSaccos.map((s) {
                      final id = s['id'] as String;
                      final name = s['name'] as String? ?? 'SACCO';
                      final district = s['district'] as String? ?? '';
                      final reg = s['registration_number'] as String? ?? '';
                      final busy = _requesting.contains(id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
                                  const SizedBox(height: 2),
                                  Text([district, reg].where((x) => x.isNotEmpty).join(' · '),
                                      style: TextStyle(fontSize: 11, color: AppTheme.gray)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: busy ? null : () => _requestJoin(id, name, lang),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.navy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              child: busy
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(en ? 'Request' : 'Omba', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: const DriverSubPageNavBar(),
    );
  }

  static const List<Map<String, String>> _payMethods = [
    {'v': 'mpesa', 'l': 'M-Pesa'},
    {'v': 'airtel_money', 'l': 'Airtel Money'},
    {'v': 'mixx', 'l': 'Mixx by Yas'},
    {'v': 'cash', 'l': 'Cash / Fedha'},
    {'v': 'bank', 'l': 'Bank / Benki'},
  ];

  // ─── AKIBA (savings accounts) ───────────────────────────
  Widget _akibaSection(bool en, LanguageProvider lang, String saccoId, List<dynamic> saccoAkiba) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings, size: 18, color: AppTheme.green),
              const SizedBox(width: 8),
              Text(en ? 'Akiba (Savings)' : 'Akiba', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _createAkiba(lang, saccoId),
                icon: const Icon(Icons.add, size: 16),
                label: Text(en ? 'New' : 'Mpya'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.green, padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (saccoAkiba.isEmpty)
            Text(en ? 'No savings account yet. Create one to start saving.' : 'Bado huna akaunti ya akiba. Tengeneza moja kuanza kuweka akiba.',
                style: TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic, fontSize: 13))
          else
            ...saccoAkiba.map((a) {
              final acc = a as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34, alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppTheme.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.account_balance_wallet, color: AppTheme.green, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc['name']?.toString() ?? 'Akiba',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 14)),
                          Text(_fmt(_num(acc['balance_tsh'])), style: TextStyle(fontSize: 12, color: AppTheme.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _akibaDeposit(acc, lang),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.green, side: BorderSide(color: AppTheme.green), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                      child: Text(en ? 'Deposit' : 'Weka', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _createAkiba(LanguageProvider lang, String saccoId) {
    final en = lang.locale == 'en';
    final nameCtrl = TextEditingController();
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(en ? 'New Savings Account' : 'Akaunti Mpya ya Akiba', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: en ? 'Account name' : 'Jina la akaunti',
              hintText: en ? 'e.g. Emergency, School Fees' : 'mf. Dharura, Ada ya Shule',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(en ? 'Cancel' : 'Ghairi')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.length < 2) return;
                      setSt(() => saving = true);
                      try {
                        await _api.post('/driver/sacco/akiba-accounts', body: {
                          'name': name,
                          'sacco_id': saccoId,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) _load();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating));
                        }
                      } finally {
                        if (ctx.mounted) setSt(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(en ? 'Create' : 'Tengeneza'),
            ),
          ],
        ),
      ),
    );
  }

  void _akibaDeposit(Map<String, dynamic> account, LanguageProvider lang) {
    final en = lang.locale == 'en';
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String method = 'mpesa';
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('${en ? 'Save to' : 'Weka kwenye'} "${account['name']}"', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: en ? 'Amount' : 'Kiasi', prefixText: 'TSh ')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: InputDecoration(labelText: en ? 'Payment Method' : 'Njia ya Malipo'),
                items: _payMethods.map((m) => DropdownMenuItem(value: m['v'], child: Text(m['l']!))).toList(),
                onChanged: (v) => setSt(() => method = v ?? 'mpesa'),
              ),
              const SizedBox(height: 12),
              TextField(controller: refCtrl, decoration: InputDecoration(labelText: en ? 'Reference (optional)' : 'Kumbukumbu (si lazima)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(en ? 'Cancel' : 'Ghairi')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt <= 0) return;
                setSt(() => saving = true);
                try {
                  final res = await _api.post('/driver/sacco/akiba-deposit', body: {
                    'savings_account_id': account['id'],
                    'amount_tsh': amt,
                    'collection_method': method,
                    'reference': refCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(en
                          ? 'Saved ${_fmt(amt)}. New balance: ${_fmt(_num(res['new_balance_tsh']))}'
                          : 'Umeweka ${_fmt(amt)}. Salio: ${_fmt(_num(res['new_balance_tsh']))}'),
                      backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating));
                    _load();
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating));
                } finally {
                  if (ctx.mounted) setSt(() => saving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(en ? 'Save' : 'Weka'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MICHANGO (contribution plans) ──────────────────────
  Widget _michangoSection(bool en, LanguageProvider lang, String saccoId, List<dynamic> saccoMichango) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism, size: 18, color: AppTheme.gold),
              const SizedBox(width: 8),
              Text(en ? 'Michango (Contributions)' : 'Michango', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
            ],
          ),
          const SizedBox(height: 6),
          if (saccoMichango.isEmpty)
            Text(en ? 'Your SACCO has not defined any contribution plans yet.' : 'SACCO yako bado haijaweka mipango ya michango.',
                style: TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic, fontSize: 13))
          else
            ...saccoMichango.map((p) {
              final plan = p as Map<String, dynamic>;
              final amount = _num(plan['amount_tsh']);
              final freq = (plan['frequency'] ?? 'monthly').toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34, alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.payments, color: AppTheme.gold, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((en ? plan['name'] : (plan['name_sw'] ?? plan['name']))?.toString() ?? 'Michango',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 14)),
                          Text('${_fmt(amount)} · ${_freqLabel(freq, en)}',
                              style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _payMichango(plan, lang),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navy, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      child: Text(en ? 'Pay' : 'Lipa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _freqLabel(String f, bool en) {
    switch (f) {
      case 'daily': return en ? 'Daily' : 'Kila siku';
      case 'weekly': return en ? 'Weekly' : 'Kila wiki';
      case 'monthly': return en ? 'Monthly' : 'Kila mwezi';
      case 'quarterly': return en ? 'Quarterly' : 'Kila robo';
      case 'yearly': return en ? 'Yearly' : 'Kila mwaka';
      case 'one_off': return en ? 'One-off' : 'Mara moja';
      default: return f;
    }
  }

  void _payMichango(Map<String, dynamic> plan, LanguageProvider lang) {
    final en = lang.locale == 'en';
    final amountCtrl = TextEditingController(text: _num(plan['amount_tsh']).round().toString());
    final refCtrl = TextEditingController();
    String method = 'mpesa';
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('${en ? 'Pay' : 'Lipa'} "${en ? plan['name'] : (plan['name_sw'] ?? plan['name'])}"', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: en ? 'Amount' : 'Kiasi', prefixText: 'TSh ')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: InputDecoration(labelText: en ? 'Payment Method' : 'Njia ya Malipo'),
                items: _payMethods.map((m) => DropdownMenuItem(value: m['v'], child: Text(m['l']!))).toList(),
                onChanged: (v) => setSt(() => method = v ?? 'mpesa'),
              ),
              const SizedBox(height: 12),
              TextField(controller: refCtrl, decoration: InputDecoration(labelText: en ? 'Reference (optional)' : 'Kumbukumbu (si lazima)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(en ? 'Cancel' : 'Ghairi')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt <= 0) return;
                setSt(() => saving = true);
                try {
                  final res = await _api.post('/driver/sacco/michango-pay', body: {
                    'plan_id': plan['id'],
                    'amount_tsh': amt,
                    'collection_method': method,
                    'reference': refCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(en
                          ? 'Contributed ${_fmt(_num(res['amount_tsh']))} to ${res['plan_name']}'
                          : 'Umechangia ${_fmt(_num(res['amount_tsh']))}'),
                      backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating));
                    _load();
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating));
                } finally {
                  if (ctx.mounted) setSt(() => saving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navy),
              child: saving
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy))
                  : Text(en ? 'Pay' : 'Lipa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.gold),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(text, style: TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic, height: 1.4)),
    );
  }
}

/// Expandable loan card: summary + tap to load repayments and penalty.
class _LoanCard extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic> loan;
  final LanguageProvider lang;
  const _LoanCard({required this.api, required this.loan, required this.lang});

  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  bool _expanded = false;
  bool _loading = false;
  List<dynamic> _repayments = [];
  Map<String, dynamic>? _detail;

  num _num(dynamic v) => v == null ? 0 : (v is num ? v : (num.tryParse(v.toString()) ?? 0));
  String _fmt(num v) {
    final s = v.round().toString();
    return 'TSh ${s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'repaid': return AppTheme.green;
      case 'pending': return AppTheme.orange;
      case 'approved':
      case 'active':
      case 'disbursed': return AppTheme.accent;
      default: return AppTheme.red;
    }
  }

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && _detail == null) {
      setState(() => _loading = true);
      try {
        final res = await widget.api.get('/loans/${widget.loan['id']}/repayments');
        _detail = (res['loan'] as Map?)?.cast<String, dynamic>();
        _repayments = res['repayments'] as List? ?? [];
      } catch (e) {
        debugPrint('repayments: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.lang.locale == 'en';
    final l = widget.loan;
    final amount = _num(l['amount_tsh']);
    final repaid = _num(l['total_repaid']);
    final remaining = _num(l['remaining_balance']);
    final missed = _num(l['missed_payments_count']).round();
    final penalty = _num(l['penalty_tsh']);
    final status = (l['status'] as String?) ?? 'pending';
    final purpose = (l['loan_purpose'] as String?) ?? 'loan';
    final progress = amount > 0 ? (repaid / amount).clamp(0.0, 1.0).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${widget.lang.translate(purpose).toUpperCase()} ${en ? 'LOAN' : 'MKOPO'}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(status.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status))),
                      ),
                      const SizedBox(width: 6),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.gray),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _kv(en ? 'Amount' : 'Kiasi', _fmt(amount)),
                      _kv(en ? 'Remaining' : 'Imebaki', _fmt(remaining),
                          color: remaining > 0 ? AppTheme.red : AppTheme.green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 7,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(status == 'repaid' ? AppTheme.green : AppTheme.accent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(progress * 100).round()}% ${en ? 'repaid' : 'imelipwa'}',
                      style: TextStyle(fontSize: 11, color: AppTheme.gray)),
                  if (missed > 0 || penalty > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              en
                                  ? '$missed missed payment(s) · Penalty: ${_fmt(penalty)}'
                                  : 'Malipo $missed yaliyokosa · Faini: ${_fmt(penalty)}',
                              style: TextStyle(fontSize: 12, color: AppTheme.red, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(en ? 'Repayment History' : 'Historia ya Marejesho',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 13)),
                        const SizedBox(height: 8),
                        if (_repayments.isEmpty)
                          Text(en ? 'No repayments recorded yet.' : 'Bado hakuna marejesho yaliyorekodiwa.',
                              style: TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic, fontSize: 13))
                        else
                          ..._repayments.map((r) {
                            final amt = _num(r['amount']);
                            final method = (r['repayment_method'] ?? '').toString();
                            final date = (r['date'] ?? '').toString().split('T').first;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34, height: 34, alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: AppTheme.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.payments, color: AppTheme.green, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_fmt(amt),
                                            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 14)),
                                        Text('$date · $method', style: TextStyle(fontSize: 11, color: AppTheme.gray)),
                                      ],
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
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.gray)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color ?? AppTheme.navy)),
      ],
    );
  }
}
