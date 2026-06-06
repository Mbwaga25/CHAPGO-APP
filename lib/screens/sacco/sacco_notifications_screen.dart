import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';

class SaccoNotificationsScreen extends StatefulWidget {
  const SaccoNotificationsScreen({super.key});

  @override
  State<SaccoNotificationsScreen> createState() => _SaccoNotificationsScreenState();
}

class _SaccoNotificationsScreenState extends State<SaccoNotificationsScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/sacco/notifications');
      setState(() {
        _notifications = res['notifications'] ?? [];
      });
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _api.put('/sacco/notifications/$id/read');
      setState(() {
        for (var n in _notifications) {
          if (n['id'] == id) {
            n['is_read'] = 1;
          }
        }
      });
    } catch (e) {
      debugPrint('Failed to mark read: $e');
    }
  }

  Future<void> _markAllRead() async {
    final lang = context.read<LanguageProvider>();
    try {
      await _api.put('/sacco/notifications/read-all');
      setState(() {
        for (var n in _notifications) {
          n['is_read'] = 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('success') ?? 'Success'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('Failed to mark all read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isSw = lang.locale == 'sw';

    final titleText = lang.locale == 'en' ? 'Sacco Notifications' : 'Taarifa za Sacco';
    final markAllText = lang.locale == 'en' ? 'Mark All Read' : 'Weka Zote Zimesomwa';
    final noNotifsText = lang.locale == 'en' ? 'No notifications yet.' : 'Hakuna taarifa bado.';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          if (_notifications.any((n) => n['is_read'] == 0 || n['is_read'] == false))
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                markAllText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none, size: 64, color: AppTheme.grayLight),
                      const SizedBox(height: 16),
                      Text(
                        noNotifsText,
                        style: const TextStyle(fontSize: 16, color: AppTheme.gray, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      final isRead = n['is_read'] == 1 || n['is_read'] == true;
                      final title = isSw ? (n['title_sw'] ?? n['title']) : n['title'];
                      final message = isSw ? (n['message_sw'] ?? n['message']) : n['message'];
                      final dateStr = n['created_at'] != null
                          ? DateTime.parse(n['created_at']).toLocal().toString().substring(0, 16)
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isRead ? Colors.white : Colors.blue[50]?.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          side: isRead ? BorderSide.none : const BorderSide(color: Colors.blue, width: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!isRead) {
                              _markRead(n['id']);
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: isRead ? Colors.grey[200] : AppTheme.navy,
                            child: Icon(
                              isRead ? Icons.notifications_none : Icons.notifications_active,
                              color: isRead ? Colors.grey : AppTheme.gold,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(message, style: const TextStyle(color: AppTheme.navy, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(dateStr, style: const TextStyle(color: AppTheme.gray, fontSize: 11)),
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
