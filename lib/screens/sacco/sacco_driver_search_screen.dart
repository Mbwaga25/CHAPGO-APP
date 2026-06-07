import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'sacco_driver_detail_screen.dart';

class SaccoDriverSearchScreen extends StatefulWidget {
  const SaccoDriverSearchScreen({super.key});

  @override
  State<SaccoDriverSearchScreen> createState() => _SaccoDriverSearchScreenState();
}

class _SaccoDriverSearchScreenState extends State<SaccoDriverSearchScreen> {
  final _searchController = TextEditingController();
  final _api = ApiService();
  List<dynamic> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(LanguageProvider lang) async {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.locale == 'en'
                ? 'Type at least 3 characters to search'
                : 'Andika herufi 3 au zaidi ili kutafuta',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _searching = true);
    try {
      final res = await _api.get('/sacco/drivers/search-all?query=$query');
      setState(() {
        _results = res['drivers'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('system_drivers_search') ?? 'Search Drivers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: lang.translate('search_system_drivers_hint') ?? 'Search by Name, Phone, Plate or ID',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(lang),
                ),
              ),
              onSubmitted: (_) => _performSearch(lang),
            ),
            const SizedBox(height: 16),
            if (_searching)
              const LinearProgressIndicator()
            else
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          lang.locale == 'en'
                              ? 'No drivers found.'
                              : 'Hakuna dereva aliyepatikana.',
                          style: const TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, idx) {
                          final d = _results[idx];
                          final score = double.tryParse(d['score']?.toString() ?? '') ?? 0.0;
                          final tier = d['tier'] as String? ?? 'unranked';
                          final isMember = d['sacco_name'] != null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(d['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${d['phone']} | ${d['vehicle_plate'] ?? ""}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Score: ${score.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isMember ? Colors.green.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isMember ? (d['sacco_name'] ?? 'Sacco Member') : 'No Sacco',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMember ? Colors.green.shade800 : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SaccoDriverDetailScreen(driverId: d['id']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
