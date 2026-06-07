import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class OperatorsScreen extends StatefulWidget {
  final bool isEmbedded;
  const OperatorsScreen({super.key, this.isEmbedded = false});

  @override
  State<OperatorsScreen> createState() => _OperatorsScreenState();
}

class _OperatorsScreenState extends State<OperatorsScreen> {
  final _api = ApiService();
  List<dynamic> _operators = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadOperators();
      }
    });
  }

  Future<void> _loadOperators() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/station/operators');
      setState(() {
        _operators = res['operators'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindikana kupakia wafanyakazi: $e'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openAddOperatorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'attendant';
    String selectedCountryCode = '+255';
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            Future<void> submit() async {
              final name = nameController.text.trim();
              final rawPhone = phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
              final password = passwordController.text;

              if (name.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jina lazima liwe angalau herufi 3')),
                );
                return;
              }

              // Normalize phone
              String phone = rawPhone;
              if (!phone.startsWith('+')) {
                if (phone.startsWith('0')) {
                  phone = selectedCountryCode + phone.substring(1);
                } else {
                  phone = selectedCountryCode + phone;
                }
              }

              if (!RegExp(r'^\+255\d{9}$').hasMatch(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Namba ya simu lazima ianzie na +255 ikifuatiwa na tarakimu 9')),
                );
                return;
              }

              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nenosiri lazima liwe na angalau herufi 6')),
                );
                return;
              }

              setDialogState(() => submitting = true);

              try {
                await _api.post('/station/operators', body: {
                  'full_name': name,
                  'phone': phone,
                  'password': password,
                  'role': selectedRole,
                });

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mfanyakazi mpya amesajiliwa kikamilifu!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadOperators();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Usajili umeshindikana: $e'),
                    backgroundColor: AppTheme.red,
                  ),
                );
              } finally {
                setDialogState(() => submitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: AppTheme.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'Weka Mfanyakazi Mpya',
                style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Jina Kamili',
                        hintText: 'John Doe',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCountryCode,
                              items: const [
                                DropdownMenuItem(value: '+255', child: Text('🇹🇿 +255')),
                                DropdownMenuItem(value: '+254', child: Text('🇰🇪 +254')),
                                DropdownMenuItem(value: '+256', child: Text('🇺🇬 +256')),
                              ],
                              onChanged: (v) {
                                setDialogState(() {
                                  selectedCountryCode = v ?? '+255';
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Namba ya Simu',
                              hintText: '712345678',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nenosiri (Password)',
                        hintText: '••••••••',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Wadhifa (Role)'),
                      items: const [
                        DropdownMenuItem(value: 'attendant', child: Text('Attendant (Mhudumu)')),
                        DropdownMenuItem(value: 'supervisor', child: Text('Supervisor (Msimamizi)')),
                        DropdownMenuItem(value: 'manager', child: Text('Manager (Meneja)')),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          selectedRole = v ?? 'attendant';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Ghairi', style: TextStyle(color: AppTheme.gray)),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.white,
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                        )
                      : const Text('Hifadhi'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wafanyakazi wa Kituo'),
        leading: widget.isEmbedded
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddOperatorDialog,
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.white,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOperators,
              child: _operators.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Center(
                          child: Text(
                            'Hakuna wafanyakazi wengine bado.',
                            style: TextStyle(
                              color: AppTheme.grayLight,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _operators.length,
                      itemBuilder: (ctx, i) {
                        final op = _operators[i];
                        final name = op['full_name'] ?? '';
                        final phone = op['phone'] ?? '';
                        final role = op['role'] ?? 'attendant';
                        final created = op['created_at'] != null
                            ? op['created_at'].toString().substring(0, 10)
                            : '';
                        final lastLogin = op['last_login_at'] != null
                            ? op['last_login_at'].toString().substring(0, 16).replaceAll('T', ' ')
                            : 'Bado hajaingia';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.navy,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: AppTheme.gray),
                                    const SizedBox(width: 6),
                                    Text(phone, style: const TextStyle(fontSize: 14, color: AppTheme.gray)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: AppTheme.gray),
                                    const SizedBox(width: 6),
                                    Text('Last Login: $lastLogin', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Amesajiliwa: $created',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.grayLight),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
