import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class AdminScoreTiersScreen extends StatefulWidget {
  const AdminScoreTiersScreen({super.key});

  @override
  State<AdminScoreTiersScreen> createState() => _AdminScoreTiersScreenState();
}

class _AdminScoreTiersScreenState extends State<AdminScoreTiersScreen> {
  final _api = ApiService();
  List<dynamic> _tiers = [];
  bool _loading = true;

  List<Map<String, String>> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _api.setToken(user.token);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final productsRes = await _api.get('/loans/products');
      if (productsRes is List) {
        _availableProducts = productsRes.map<Map<String, String>>((p) => {
          'code': p['code'].toString(),
          'name': '${p['name']} (${p['name_sw']})',
        }).toList();
      }

      final tiersRes = await _api.get('/scores/admin/tiers');
      if (tiersRes is List) {
        _tiers = tiersRes;
      }
    } catch (e) {
      debugPrint('data load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load configuration data: $e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadTiers() {
    _loadData();
  }

  void _showFormDialog({Map<String, dynamic>? tier}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TierFormDialog(
        tier: tier,
        api: _api,
        availableProducts: _availableProducts,
        onSuccess: () {
          Navigator.pop(ctx);
          _loadTiers();
        },
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> tier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tier', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the "${tier['name'].toString().toUpperCase()}" tier? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.delete('/scores/admin/tiers/${tier['id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Tier deleted successfully'), backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating),
          );
        }
        _loadTiers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Boda Score Tiers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTiers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tiers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.layers_clear, size: 64, color: AppTheme.grayLight),
                      const SizedBox(height: 16),
                      Text('No custom score tiers found', style: AppTheme.headingMedium),
                      const SizedBox(height: 8),
                      Text('Tap the + button to add a new tier config', style: TextStyle(color: AppTheme.gray)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tiers.length,
                  itemBuilder: (context, idx) {
                    final t = _tiers[idx];
                    final name = t['name'].toString().toUpperCase();
                    final minScore = t['min_score'] ?? 0;
                    final minLimit = double.tryParse(t['min_loan_limit'].toString()) ?? 0;
                    final maxLimit = double.tryParse(t['max_loan_limit'].toString()) ?? 0;
                    final rate = double.tryParse(t['interest_rate_pct'].toString()) ?? 0;
                    final List<dynamic> products = t['loan_products'] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.border, width: 1),
                      ),
                      elevation: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [AppTheme.surface, AppTheme.surface.withValues(alpha: 0.95)],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gold.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: AppTheme.goldLight,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Score: $minScore+',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, color: AppTheme.gold, size: 20),
                                        onPressed: () => _showFormDialog(tier: t),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: AppTheme.red, size: 20),
                                        onPressed: () => _confirmDelete(t),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricCol('Loan Limits', 'TZS ${minLimit.toInt().toLocaleString()} - ${maxLimit.toInt().toLocaleString()}'),
                                  ),
                                  Expanded(
                                    child: _metricCol('Interest Rate', '${rate.toStringAsFixed(1)}% APR'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Eligible Products:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              products.isEmpty
                                  ? const Text('None (Ineligible)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: products.map((p) {
                                        final nameMap = _availableProducts.firstWhere(
                                          (ap) => ap['code'] == p,
                                          orElse: () => {'code': p.toString(), 'name': p.toString()},
                                        );
                                        return Chip(
                                          label: Text(
                                            nameMap['name']!.split(' ')[0],
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                          ),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _metricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TierFormDialog extends StatefulWidget {
  final Map<String, dynamic>? tier;
  final ApiService api;
  final List<Map<String, String>> availableProducts;
  final VoidCallback onSuccess;

  const _TierFormDialog({
    this.tier,
    required this.api,
    required this.availableProducts,
    required this.onSuccess,
  });

  @override
  State<_TierFormDialog> createState() => _TierFormDialogState();
}

class _TierFormDialogState extends State<_TierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _minScoreCtrl = TextEditingController();
  final _minLoanCtrl = TextEditingController();
  final _maxLoanCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final List<String> _selectedProducts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.tier != null) {
      _nameCtrl.text = widget.tier!['name'] ?? '';
      _minScoreCtrl.text = (widget.tier!['min_score'] ?? '').toString();
      _minLoanCtrl.text = (widget.tier!['min_loan_limit'] ?? '').toString();
      _maxLoanCtrl.text = (widget.tier!['max_loan_limit'] ?? '').toString();
      _rateCtrl.text = (widget.tier!['interest_rate_pct'] ?? '').toString();

      final List<dynamic> products = widget.tier!['loan_products'] ?? [];
      _selectedProducts.addAll(products.map((p) => p.toString()));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minScoreCtrl.dispose();
    _minLoanCtrl.dispose();
    _maxLoanCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'name': _nameCtrl.text.trim().toLowerCase(),
      'min_score': int.parse(_minScoreCtrl.text.trim()),
      'min_loan_limit': double.parse(_minLoanCtrl.text.trim()),
      'max_loan_limit': double.parse(_maxLoanCtrl.text.trim()),
      'interest_rate_pct': double.parse(_rateCtrl.text.trim()),
      'loan_products': _selectedProducts,
    };

    try {
      if (widget.tier == null) {
        await widget.api.post('/scores/admin/tiers', body: payload);
      } else {
        await widget.api.put('/scores/admin/tiers/${widget.tier!['id']}', body: payload);
      }
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.tier == null ? 'Create Tier' : 'Edit Tier';

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tier Name (e.g. Platinum)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minScoreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min Score Border (0 - 1000)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final s = int.tryParse(v.trim());
                    if (s == null || s < 0 || s > 1000) return 'Must be 0-1000';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minLoanCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min Loan Limit (TZS)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxLoanCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Loan Limit (TZS)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Interest Rate (% APR)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Loan Products:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...widget.availableProducts.map((p) {
                  final code = p['code']!;
                  final isChecked = _selectedProducts.contains(code);
                  return CheckboxListTile(
                    title: Text(p['name']!, style: const TextStyle(fontSize: 12)),
                    value: isChecked,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedProducts.add(code);
                        } else {
                          _selectedProducts.remove(code);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// Extension to format integer numbers into comma-separated currency values (e.g. 1,000,000)
extension IntFormatter on int {
  String toLocaleString() {
    final str = toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        buffer.write(',');
        count = 0;
      }
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }
}
