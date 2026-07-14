import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/audit.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<AuditEntry> _entries = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final api = ApiService()..setToken(user.token);
    setState(() => _loading = true);
    try {
      final a = await api.get('/admin/audit-log?limit=50');
      setState(() {
        _entries = (a['entries'] as List?)?.map((e) => AuditEntry.fromJson(e)).toList() ?? [];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Audit Log', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text('Every sensitive action is recorded here. Review regularly.', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_entries.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No audit entries', style: TextStyle(color: AppTheme.grayLight, fontStyle: FontStyle.italic)))))
          else
            ..._entries.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.action, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(width: 8),
                              if (e.actorPhone != null)
                                Text(e.actorPhone!, style: TextStyle(fontSize: 11, color: AppTheme.gray)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${e.actorType} · ${e.resourceType ?? '—'} · ${e.ipAddress ?? '—'}',
                            style: TextStyle(fontSize: 11, color: AppTheme.gray),
                          ),
                          Text(
                            _formatDate(e.occurredAt),
                            style: TextStyle(fontSize: 11, color: AppTheme.grayLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
