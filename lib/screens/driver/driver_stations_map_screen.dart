import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/driver_subpage_navbar.dart';

import '../../widgets/map_view_stub.dart'
    if (dart.library.html) '../../widgets/map_view_web.dart' as mapper;

class DriverStationsMapScreen extends StatefulWidget {
  final int initialTab;
  const DriverStationsMapScreen({super.key, this.initialTab = 0});

  @override
  State<DriverStationsMapScreen> createState() => _DriverStationsMapScreenState();
}

class _DriverStationsMapScreenState extends State<DriverStationsMapScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _stations = [];
  late TabController _tabController;
  
  String _selectedDistrict = '';
  String? _selectedRefuelStation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _loadSelectedRefuelStation();
    _loadStations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedRefuelStation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRefuelStation = prefs.getString('selected_refuel_station');
    });
  }

  Future<void> _selectStation(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_refuel_station', name);
    setState(() {
      _selectedRefuelStation = name;
    });

    final lang = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('success')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text('${lang.translate('station_selected') ?? 'Refuel Choice Confirmed'}:'),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    try {
      final path = _selectedDistrict.isNotEmpty ? '/station/list?district=$_selectedDistrict' : '/station/list';
      final res = await _api.get(path);
      setState(() {
        _stations = res['stations'] ?? [];
      });
    } catch (e) {
      debugPrint('Failed to load stations: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('menu_stations')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          tabs: [
            Tab(text: lang.translate('menu_stations_map')),
            Tab(text: lang.translate('menu_stations_list')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // District filter bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lang.translate('district') ?? 'District'}:',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                      ),
                      DropdownButton<String>(
                        value: _selectedDistrict,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedDistrict = val;
                            });
                            _loadStations();
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All / Zote')),
                          DropdownMenuItem(value: 'Kinondoni', child: Text('Kinondoni')),
                          DropdownMenuItem(value: 'Ilala', child: Text('Ilala')),
                          DropdownMenuItem(value: 'Temeke', child: Text('Temeke')),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_selectedRefuelStation != null)
                  Container(
                    width: double.infinity,
                    color: Colors.green[50],
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.local_gas_station, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${lang.translate('station_selected') ?? 'Refueling Choice'}: $_selectedRefuelStation',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('selected_refuel_station');
                            setState(() {
                              _selectedRefuelStation = null;
                            });
                          },
                          child: const Icon(Icons.clear, color: Colors.green, size: 18),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(), // Prevent horizontal swipe conflicts with web mapping
                    children: [
                      // Map view
                      mapper.ActiveMapView(
                        stations: _stations,
                        onStationSelected: _selectStation,
                        selectedStationName: _selectedRefuelStation,
                      ),
                      // Directory list view
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stations.length,
                        itemBuilder: (context, i) {
                          final s = _stations[i];
                          final name = s['name'] as String? ?? '';
                          final addr = s['address'] as String? ?? '';
                          final isSelected = _selectedRefuelStation == name;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected ? Colors.green[50]?.withOpacity(0.5) : Colors.white,
                            shape: isSelected
                                ? RoundedRectangleBorder(
                                    side: const BorderSide(color: Colors.green, width: 1),
                                    borderRadius: BorderRadius.circular(10),
                                  )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 15),
                                      ),
                                      if (isSelected)
                                        const Chip(
                                          label: Text('REFUEL CHOSEN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          backgroundColor: Colors.green,
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${s['district'] ?? ''} - ${s['ward'] ?? ''}', style: const TextStyle(color: AppTheme.gray, fontSize: 12)),
                                  if (addr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(addr, style: const TextStyle(color: AppTheme.navy, fontSize: 13)),
                                  ],
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _selectStation(name),
                                        icon: const Icon(Icons.local_gas_station, size: 16),
                                        label: Text(lang.translate('station_select_btn')),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isSelected ? Colors.green : AppTheme.navy,
                                          side: BorderSide(color: isSelected ? Colors.green : AppTheme.navy),
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
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: DriverSubPageNavBar(
        type: 'stations',
        activeIndex: _tabController.index + 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/home',
              (route) => false,
              arguments: {'tab': 0},
            );
          } else {
            _tabController.animateTo(index - 1);
            setState(() {});
          }
        },
      ),
    );
  }
}
