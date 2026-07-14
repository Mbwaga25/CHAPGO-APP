import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class AdminEscalationsScreen extends StatefulWidget {
  const AdminEscalationsScreen({super.key});

  @override
  State<AdminEscalationsScreen> createState() => _AdminEscalationsScreenState();
}

class _AdminEscalationsScreenState extends State<AdminEscalationsScreen> {
  final _api = ApiService();
  List<dynamic> _escalations = [];
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
        _loadEscalations();
      }
    });
  }

  Future<void> _loadEscalations() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/escalations');
      setState(() {
        _escalations = res['escalations'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindikana kupakia escalations: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resolveEscalation(String escalationId) async {
    final notesController = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text('Resolve Escalation', style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
              content: TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ingiza maelezo ya utatuzi hapa...',
                  labelText: 'Maelezo ya Utatuzi (Resolution Notes)',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Ghairi', style: TextStyle(color: AppTheme.gray)),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final notes = notesController.text.trim();
                          if (notes.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tafadhali ingiza maelezo ya utatuzi')),
                            );
                            return;
                          }
                          setDialogState(() => submitting = true);
                          try {
                            await _api.post('/admin/escalations/$escalationId/resolve', body: {'resolution_notes': notes});
                            Navigator.pop(ctx);
                            _loadEscalations();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Imeshindikana: $e'), backgroundColor: AppTheme.red),
                            );
                          } finally {
                            setDialogState(() => submitting = false);
                          }
                        },
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tatua'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  BadgeVariant _getSeverityVariant(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return BadgeVariant.urgent;
      case 'normal':
      default:
        return BadgeVariant.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadEscalations,
      child: _escalations.isEmpty
          ? Center(
              child: Text(
                'Hakuna escalations zilizopo kwa sasa',
                style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _escalations.length,
              itemBuilder: (ctx, idx) {
                final esc = _escalations[idx];
                final id = esc['id'] ?? '';
                final name = esc['driver_name'] ?? 'Dereva Asiyejulikana';
                final phone = esc['phone'] ?? '';
                final reason = esc['reason'] ?? '';
                final msg = esc['last_message'] ?? '';
                final severity = esc['severity'] ?? 'normal';
                final status = esc['status'] ?? 'open';
                final resolved = status == 'resolved';
                final notes = esc['resolution_notes'] ?? '';

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
                            Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy)),
                            StatusBadge(
                              label: severity.toUpperCase(),
                              variant: _getSeverityVariant(severity),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(phone, style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                        const SizedBox(height: 8),
                        Text('Sababu: $reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Ujumbe wa mwisho:\n"$msg"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.gray)),
                        ),
                        if (resolved) ...[
                          const SizedBox(height: 10),
                          Text('Utatuzi: $notes', style: TextStyle(fontSize: 12, color: AppTheme.green, fontWeight: FontWeight.bold)),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(
                              label: status.toUpperCase(),
                              variant: resolved ? BadgeVariant.active : BadgeVariant.urgent,
                            ),
                            if (!resolved)
                              ElevatedButton.icon(
                                onPressed: () => _resolveEscalation(id),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.gold,
                                  foregroundColor: AppTheme.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
