import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import 'sacco_driver_search_screen.dart';
import 'sacco_loan_detail_screen.dart';
import 'sacco_notifications_screen.dart';
import 'sacco_driver_detail_screen.dart';

class SaccoHomeScreen extends StatefulWidget {
  const SaccoHomeScreen({super.key});

  @override
  State<SaccoHomeScreen> createState() => _SaccoHomeScreenState();
}

class _SaccoHomeScreenState extends State<SaccoHomeScreen> {
  final _api = ApiService();
  bool _loadingOverview = true;
  bool _loadingMembers = true;
  bool _loadingCollections = true;
  bool _loadingLoans = true;
  bool _loadingStandards = true;
  int _currentIndex = 0;
  int _unreadNotificationsCount = 0;

  // Data states
  Map<String, dynamic> _overviewData = {};
  List<dynamic> _members = [];
  List<dynamic> _collections = [];
  List<dynamic> _pendingLoans = [];
  List<dynamic> _saccoLoans = [];
  List<dynamic> _allSaccoLoans = [];
  bool _loadingAllSaccoLoans = true;
  String _selectedLoanFilter = 'all';
  final _loanSearchController = TextEditingController();
  Timer? _loanDebounceTimer;

  // Standards Controllers
  final _minBodaScoreController = TextEditingController();
  final _minSavingsController = TextEditingController();
  final _multiplierController = TextEditingController();

  // Search & Selector Controllers
  final _memberSearchController = TextEditingController();
  final _colMemberSearchController = TextEditingController();
  final _colAmountController = TextEditingController();
  final _colReferenceController = TextEditingController();
  String? _selectedColAccountId;
  String _selectedColMethod = 'cash';
  bool _savingCollection = false;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }

    _loadAllData();
  }

  @override
  void dispose() {
    _minBodaScoreController.dispose();
    _minSavingsController.dispose();
    _multiplierController.dispose();
    _loanSearchController.dispose();
    _memberSearchController.dispose();
    _colMemberSearchController.dispose();
    _colAmountController.dispose();
    _colReferenceController.dispose();
    _loanDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadNotificationsCount() async {
    if (!mounted) return;
    try {
      final res = await _api.get('/sacco/notifications');
      final list = res['notifications'] ?? [];
      final unread = list.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = unread;
        });
      }
    } catch (e) {
      debugPrint('Failed to load unread count: $e');
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadOverview(),
      _loadMembers(),
      _loadCollections(),
      _loadPendingLoans(),
      _loadSaccoLoans(),
      _loadAllSaccoLoans(),
      _loadStandards(),
      _loadUnreadNotificationsCount(),
    ]);
  }

  void _refreshTab(int index) {
    _loadUnreadNotificationsCount();
    switch (index) {
      case 0:
        _loadOverview();
        _loadCollections();
        break;
      case 1:
        _loadMembers();
        break;
      case 2:
        _loadMembers(); // Required to populate record collections dropdown
        _loadAllSaccoLoans();
        _loadCollections();
        break;
      case 3:
        _loadPendingLoans();
        _loadSaccoLoans();
        break;
      case 4:
        _loadStandards();
        break;
    }
  }

  Future<void> _loadAllSaccoLoans() async {
    if (!mounted) return;
    setState(() => _loadingAllSaccoLoans = true);
    try {
      final res = await _api.get('/sacco/loans?status=all');
      if (mounted) {
        setState(() {
          _allSaccoLoans = res['loans'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load all Sacco loans: $e');
    } finally {
      if (mounted) setState(() => _loadingAllSaccoLoans = false);
    }
  }

  Future<void> _loadStandards() async {
    if (!mounted) return;
    setState(() => _loadingStandards = true);
    try {
      final res = await _api.get('/sacco/standards');
      if (mounted) {
        setState(() {
          _minBodaScoreController.text = (res['min_boda_score'] ?? 50).toString();
          _minSavingsController.text = (res['min_savings_balance_tsh'] ?? 10000.0).toStringAsFixed(0);
          _multiplierController.text = (res['max_loan_limit_multiplier'] ?? 3.0).toString();
        });
      }
    } catch (e) {
      debugPrint('Failed to load standards: $e');
    } finally {
      if (mounted) setState(() => _loadingStandards = false);
    }
  }

  Future<void> _saveStandards(LanguageProvider lang) async {
    final minScore = int.tryParse(_minBodaScoreController.text) ?? 50;
    final minSavings = double.tryParse(_minSavingsController.text) ?? 10000.0;
    final multiplier = double.tryParse(_multiplierController.text) ?? 3.0;

    setState(() => _loadingStandards = true);
    try {
      await _api.post('/sacco/standards', body: {
        'min_boda_score': minScore,
        'min_savings_balance_tsh': minSavings,
        'max_loan_limit_multiplier': multiplier,
      });
      _showSnackbar(
        lang.translate('standards_updated') ?? 'Sacco standards updated successfully',
        Colors.green,
      );
      _loadStandards();
    } catch (e) {
      _showSnackbar(e.toString(), Colors.red);
    } finally {
      setState(() => _loadingStandards = false);
    }
  }

  Future<void> _loadOverview() async {
    if (!mounted) return;
    setState(() => _loadingOverview = true);
    try {
      final res = await _api.get('/sacco/overview');
      if (mounted) {
        setState(() {
          _overviewData = res;
        });
      }
    } catch (e) {
      debugPrint('Failed to load overview: $e');
    } finally {
      if (mounted) setState(() => _loadingOverview = false);
    }
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() => _loadingMembers = true);
    try {
      final res = await _api.get('/sacco/members');
      if (mounted) {
        setState(() {
          _members = res['members'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load members: $e');
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;
    setState(() => _loadingCollections = true);
    try {
      final res = await _api.get('/sacco/collections?days=30');
      if (mounted) {
        setState(() {
          _collections = res['collections'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load collections: $e');
    } finally {
      if (mounted) setState(() => _loadingCollections = false);
    }
  }

  Future<void> _loadPendingLoans() async {
    if (!mounted) return;
    try {
      final res = await _api.get('/loans/sacco/pending');
      if (mounted) {
        setState(() {
          _pendingLoans = res['loans'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load pending loans: $e');
    }
  }

  Future<void> _loadSaccoLoans() async {
    if (!mounted) return;
    setState(() => _loadingLoans = true);
    try {
      final query = _loanSearchController.text.trim();
      final res = await _api.get('/sacco/loans?status=$_selectedLoanFilter&query=$query');
      if (mounted) {
        setState(() {
          _saccoLoans = res['loans'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load Sacco loans: $e');
    } finally {
      if (mounted) setState(() => _loadingLoans = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();

    final saccoName = auth.user?.stationName ?? 'UMOBOKE SACCO';

    return Scaffold(
      appBar: AppBar(
        title: Text(saccoName),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: lang.locale == 'en' ? 'Notifications' : 'Taarifa',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SaccoNotificationsScreen()),
                  ).then((_) => _loadUnreadNotificationsCount());
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: lang.translate('system_drivers_search'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SaccoDriverSearchScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.navy),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppTheme.gold,
                child: Icon(Icons.business, color: Colors.white, size: 36),
              ),
              accountName: Text(
                auth.user?.fullName ?? saccoName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(auth.user?.phone ?? ''),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: AppTheme.navy),
                    title: Text(lang.translate('overview')),
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      setState(() => _currentIndex = 0);
                      _refreshTab(0);
                    },
                  ),
                  const Divider(),
                  
                  // Members Section
                  ExpansionTile(
                    leading: const Icon(Icons.people, color: AppTheme.navy),
                    title: Text(lang.locale == 'en' ? 'Members' : 'Wanachama'),
                    childrenPadding: const EdgeInsets.only(left: 16),
                    initiallyExpanded: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.list, color: AppTheme.gold),
                        title: Text(lang.locale == 'en' ? 'Members List' : 'Orodha ya Wanachama'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 1);
                          _refreshTab(1);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.search, color: AppTheme.gold),
                        title: Text(lang.translate('system_drivers_search') ?? 'Search Drivers'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SaccoDriverSearchScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),

                  // Collections Section
                  ListTile(
                    leading: const Icon(Icons.monetization_on, color: AppTheme.navy),
                    title: Text(lang.locale == 'en' ? 'Collections' : 'Makusanyo'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                      _refreshTab(2);
                    },
                  ),
                  const Divider(),

                  // Loans Section
                  ListTile(
                    leading: const Icon(Icons.assignment_late, color: AppTheme.navy),
                    title: Text('${lang.translate('loans')} (${_pendingLoans.length})'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 3);
                      _refreshTab(3);
                    },
                  ),
                  const Divider(),

                  // Standards Section
                  ListTile(
                    leading: const Icon(Icons.rule, color: AppTheme.navy),
                    title: Text(lang.translate('standards') ?? 'Standards'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 4);
                      _refreshTab(4);
                    },
                  ),
                   // Send Broadcast Section
                  ListTile(
                    leading: const Icon(Icons.campaign, color: AppTheme.navy),
                    title: Text(lang.locale == 'en' ? 'Send Broadcast' : 'Tuma Tangazo'),
                    onTap: () {
                      Navigator.pop(context);
                      _openBroadcastDialog(lang);
                    },
                  ),
                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(lang.translate('sign_out'), style: const TextStyle(color: Colors.red)),
                    onTap: () async {
                      Navigator.pop(context);
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(lang),
          _buildMembersTab(lang),
          _buildCollectionsTab(lang),
          _buildLoansTab(lang),
          _buildStandardsTab(lang),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _refreshTab(index);
        },
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: AppTheme.grayLight,
        backgroundColor: AppTheme.white,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: lang.translate('overview'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: lang.locale == 'en' ? 'Members' : 'Wanachama',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monetization_on_outlined),
            activeIcon: const Icon(Icons.monetization_on),
            label: lang.locale == 'en' ? 'Collections' : 'Makusanyo',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            activeIcon: const Icon(Icons.assignment_late),
            label: lang.translate('loans'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.rule_folder_outlined),
            activeIcon: const Icon(Icons.rule),
            label: lang.translate('standards') ?? 'Standards',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(LanguageProvider lang) {
    if (_loadingOverview) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeMembers = _overviewData['active_members'] ?? 0;
    final collections30d = _overviewData['collections_30d_tsh'] ?? 0.0;
    final activeLoans = _overviewData['active_loans_count'] ?? 0;
    final activeLoansVal = _overviewData['active_loans_value_tsh'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _overviewCard(
                lang.locale == 'en' ? 'Active Members' : 'Wanachama Hai',
                '$activeMembers',
                Icons.people,
                Colors.blue,
              ),
              _overviewCard(
                lang.locale == 'en' ? '30d Collections' : 'Makusanyo (Siku 30)',
                'TSh ${collections30d.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                Colors.green,
              ),
              _overviewCard(
                lang.locale == 'en' ? 'Active Loans' : 'Mikopo Inayoendelea',
                '$activeLoans',
                Icons.assignment,
                Colors.orange,
              ),
              _overviewCard(
                lang.locale == 'en' ? 'Disbursed Value' : 'Kiasi Kilichokopeshwa',
                'TSh ${activeLoansVal.toStringAsFixed(0)}',
                Icons.monetization_on,
                Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            lang.locale == 'en' ? 'Recent Sacco Collections' : 'Makusanyo ya Hivi Karibuni',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
          const SizedBox(height: 12),
          _buildCollectionsList(lang, limit: 8),
        ],
      ),
    );
  }

  Widget _overviewCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: MEMBERS LIST
  // ==========================================
  Widget _buildMembersTab(LanguageProvider lang) {
    if (_loadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    final queryText = _memberSearchController.text.toLowerCase().trim();
    final filteredMembers = _members.where((m) {
      final name = (m['full_name'] ?? '').toString().toLowerCase();
      final phone = (m['phone'] ?? '').toString().toLowerCase();
      final plate = (m['vehicle_plate'] ?? '').toString().toLowerCase();
      final chapgoId = (m['chapgo_id'] ?? '').toString().toLowerCase();
      return name.contains(queryText) ||
          phone.contains(queryText) ||
          plate.contains(queryText) ||
          chapgoId.contains(queryText);
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _openAddMemberDialog(lang),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _memberSearchController,
              onChanged: (val) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: lang.locale == 'en' ? 'Search Members' : 'Tafuta Wanachama',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _memberSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _memberSearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(
                    child: Text(
                      lang.locale == 'en'
                          ? (_members.isEmpty ? 'No Sacco members found.' : 'No matching members found.')
                          : (_members.isEmpty ? 'Hakuna wanachama wa SACCO waliopatikana.' : 'Hakuna mwanachama anayelingana.'),
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.gray),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadMembers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, i) {
                        final m = filteredMembers[i];
                        final name = m['full_name'] ?? 'Driver';
                        final phone = m['phone'] ?? '';
                        final chapgoId = m['chapgo_id'] ?? '';
                        final plate = m['vehicle_plate'] ?? '';
                        final balance = m['balance_tsh'] != null ? double.parse(m['balance_tsh'].toString()) : 0.0;
                        final contribution = m['monthly_contribution_tsh'] != null ? double.parse(m['monthly_contribution_tsh'].toString()) : 0.0;
                        final joined = m['joined_at'] != null ? m['joined_at'].toString().substring(0, 10) : '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SaccoDriverDetailScreen(driverId: m['driver_id']),
                                ),
                              ).then((_) => _loadMembers());
                            },
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
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gold.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          chapgoId,
                                          style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${lang.locale == "en" ? "Phone" : "Simu"}: $phone', style: const TextStyle(color: AppTheme.gray, fontSize: 13)),
                                      Text('${lang.locale == "en" ? "Vehicle" : "Gari"}: $plate', style: const TextStyle(color: AppTheme.gray, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${lang.locale == "en" ? "Contribution" : "Michango / Mwezi"}: TSh ${contribution.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navy),
                                      ),
                                      Text(
                                        '${lang.locale == "en" ? "Savings Balance" : "Akiba"}: TSh ${balance.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${lang.locale == "en" ? "Joined" : "Alijiunga"}: $joined',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.grayLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openAddMemberDialog(LanguageProvider lang) {
    final searchController = TextEditingController();
    final contributionController = TextEditingController(text: '10000');
    List<dynamic> searchResults = [];
    bool searching = false;
    Map<String, dynamic>? selectedDriver;
    Timer? debounceTimer;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void runSearch(String val) async {
              final query = val.trim();
              if (query.length < 3) {
                setDialogState(() {
                  searchResults = [];
                });
                return;
              }
              setDialogState(() => searching = true);
              try {
                final res = await _api.get('/sacco/search-driver?query=$query');
                setDialogState(() {
                  searchResults = res['drivers'] ?? [];
                });
              } catch (e) {
                debugPrint('Search error: $e');
              } finally {
                setDialogState(() => searching = false);
              }
            }

            return AlertDialog(
              title: Text(lang.locale == 'en' ? 'Add New Sacco Member' : 'Weka Mwanachama Mpya'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: (val) {
                          if (debounceTimer?.isActive ?? false) debounceTimer?.cancel();
                          debounceTimer = Timer(const Duration(milliseconds: 300), () {
                            runSearch(val);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: lang.locale == 'en' ? 'Search Driver (Phone/Name/Plate)' : 'Tafuta Dereva (Simu/Jina/Namba ya Gari)',
                          suffixIcon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (searching)
                        const LinearProgressIndicator()
                      else if (searchResults.isEmpty && searchController.text.isNotEmpty)
                        Text(
                          lang.locale == 'en'
                              ? 'No unassigned active drivers found.'
                              : 'Hakuna dereva anayepatikana bila Sacco.',
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontStyle: FontStyle.italic),
                        )
                      else if (searchResults.isNotEmpty)
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, idx) {
                              final d = searchResults[idx];
                              final isSelected = selectedDriver?['id'] == d['id'];
                              return ListTile(
                                dense: true,
                                title: Text(d['full_name'] ?? ''),
                                subtitle: Text('${d['phone']} | ${d['vehicle_plate'] ?? ""}'),
                                selected: isSelected,
                                selectedTileColor: Colors.amber.shade50,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info_outline, color: AppTheme.navy),
                                      tooltip: lang.locale == 'en' ? 'View Details' : 'Angalia Maelezo',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SaccoDriverDetailScreen(driverId: d['id']),
                                          ),
                                        );
                                      },
                                    ),
                                    if (isSelected) const Icon(Icons.check, color: Colors.green),
                                  ],
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    selectedDriver = d;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (selectedDriver != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          color: Colors.green.shade50,
                          child: Text(
                            '${lang.locale == "en" ? "Selected" : "Umechagua"}: ${selectedDriver!["full_name"]}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contributionController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.locale == 'en' ? 'Monthly Contribution (TSh)' : 'Michango kwa Mwezi (TSh)',
                            prefixText: 'TSh ',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.locale == 'en' ? 'Cancel' : 'Ghairi'),
                ),
                ElevatedButton(
                  onPressed: selectedDriver == null
                      ? null
                      : () async {
                          final amt = double.tryParse(contributionController.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            _showSnackbar(
                              lang.locale == 'en' ? 'Invalid contribution amount' : 'Kiasi cha michango sio sahihi',
                              Colors.red,
                            );
                            return;
                          }
                          try {
                            await _api.post('/sacco/members', body: {
                              'driver_id': selectedDriver!['id'],
                              'monthly_contribution_tsh': amt,
                            });
                            Navigator.pop(context);
                            _showSnackbar(
                              lang.locale == 'en' ? 'Member added successfully!' : 'Mwanachama amewekwa kikamilifu!',
                              Colors.green,
                            );
                            _loadMembers();
                            _loadOverview();
                          } catch (e) {
                            _showSnackbar(e.toString(), Colors.red);
                          }
                        },
                  child: Text(lang.locale == 'en' ? 'Confirm' : 'Thibitisha'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openBroadcastDialog(LanguageProvider lang) {
    final titleEnController = TextEditingController();
    final titleSwController = TextEditingController();
    final msgEnController = TextEditingController();
    final msgSwController = TextEditingController();
    bool sending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(lang.locale == 'en' ? 'Send Broadcast Notification' : 'Tuma Tangazo la Mfumo'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.locale == 'en'
                            ? 'This will send a notification to all active members of your Sacco.'
                            : 'Hii itatuma taarifa kwa wanachama wote hai wa Sacco yako.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleEnController,
                        decoration: InputDecoration(
                          labelText: lang.locale == 'en' ? 'Title (English)' : 'Kichwa (English)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleSwController,
                        decoration: InputDecoration(
                          labelText: lang.locale == 'en' ? 'Title (Swahili)' : 'Kichwa (Swahili)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: msgEnController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: lang.locale == 'en' ? 'Message (English)' : 'Ujumbe (English)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: msgSwController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: lang.locale == 'en' ? 'Message (Swahili)' : 'Ujumbe (Swahili)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(context),
                  child: Text(lang.locale == 'en' ? 'Cancel' : 'Ghairi'),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final tEn = titleEnController.text.trim();
                          final tSw = titleSwController.text.trim();
                          final mEn = msgEnController.text.trim();
                          final mSw = msgSwController.text.trim();

                          if (tEn.isEmpty || tSw.isEmpty || mEn.isEmpty || mSw.isEmpty) {
                            _showSnackbar(
                              lang.locale == 'en' ? 'All fields are required' : 'Vipengele vyote vinahitajika',
                              Colors.red,
                            );
                            return;
                          }

                          setDialogState(() => sending = true);
                          try {
                            await _api.post('/sacco/campaigns', body: {
                              'title': tEn,
                              'title_sw': tSw,
                              'message': mEn,
                              'message_sw': mSw,
                            });
                            Navigator.pop(context);
                            _showSnackbar(
                              lang.locale == 'en' ? 'Broadcast sent successfully!' : 'Tangazo limetumwa kikamilifu!',
                              Colors.green,
                            );
                          } catch (e) {
                            _showSnackbar(e.toString(), Colors.red);
                          } finally {
                            setDialogState(() => sending = false);
                          }
                        },
                  child: sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(lang.locale == 'en' ? 'Send' : 'Tuma'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 3: RECORD COLLECTIONS
  // ==========================================
  Widget _buildCollectionsTab(LanguageProvider lang) {
    final methods = [
      {'val': 'cash', 'label': 'Cash / Fedha taslimu'},
      {'val': 'mpesa', 'label': 'M-Pesa'},
      {'val': 'mixx', 'label': 'Tigo Pesa / Mixx'},
      {'val': 'airtel_money', 'label': 'Airtel Money'},
      {'val': 'chapesa', 'label': 'ChaPesa'},
      {'val': 'bank', 'label': 'Bank Transfer / Benki'},
    ];

    // Filter members who have active loans (match by driver_id)
    final loanDriverIds = _allSaccoLoans
        .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'approved')
        .map((l) => l['driver_id']?.toString())
        .toSet();

    final membersWithLoans = _members.where((m) {
      return loanDriverIds.contains(m['driver_id']?.toString());
    }).toList();

    // Apply search query to the filtered list
    final searchQuery = _colMemberSearchController.text.toLowerCase().trim();
    final filteredMembers = searchQuery.isEmpty
        ? membersWithLoans
        : membersWithLoans.where((m) {
            final name = (m['full_name'] ?? '').toString().toLowerCase();
            final phone = (m['phone'] ?? '').toString().toLowerCase();
            final plate = (m['vehicle_plate'] ?? '').toString().toLowerCase();
            final acctNo = (m['account_number'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) ||
                phone.contains(searchQuery) ||
                plate.contains(searchQuery) ||
                acctNo.contains(searchQuery);
          }).toList();

    // Find selected member info
    Map<String, dynamic>? selectedMember;
    if (_selectedColAccountId != null) {
      for (final m in _members) {
        if (m['account_id']?.toString() == _selectedColAccountId) {
          selectedMember = m;
          break;
        }
      }
    }

    // Find active loan for selected member (match by driver_id)
    Map<String, dynamic>? selectedLoan;
    if (selectedMember != null) {
      final selectedDriverId = selectedMember['driver_id']?.toString();
      for (final l in _allSaccoLoans) {
        if (l['driver_id']?.toString() == selectedDriverId &&
            (l['status'] ?? '').toString().toLowerCase() == 'approved') {
          selectedLoan = l;
          break;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.locale == 'en' ? 'Record Member Loan Repayment' : 'Rekodi Malipo ya Mkopo wa Mwanachama',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
          const SizedBox(height: 4),
          Text(
            lang.locale == 'en'
                ? 'Only members with active loans are shown.'
                : 'Wanachama wenye mikopo hai pekee wanaonyeshwa.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),

          // Search bar for member
          TextField(
            controller: _colMemberSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: lang.locale == 'en' ? 'Search Member (Name/Phone/Plate)' : 'Tafuta Mwanachama (Jina/Simu/Namba)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _colMemberSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _colMemberSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Member selection list (only show when no member is selected or when searching)
          if (_selectedColAccountId == null) ...[
            if (_loadingAllSaccoLoans || _loadingMembers)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (filteredMembers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      searchQuery.isNotEmpty
                          ? (lang.locale == 'en' ? 'No matching members with active loans found.' : 'Hakuna mwanachama mwenye mkopo hai anayepatikana.')
                          : (lang.locale == 'en' ? 'No members with active loans.' : 'Hakuna wanachama wenye mikopo hai.'),
                      style: const TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredMembers.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, i) {
                    final m = filteredMembers[i];
                    final name = m['full_name'] ?? 'Driver';
                    final phone = m['phone'] ?? '';
                    final plate = m['vehicle_plate'] ?? '';
                    final acctNo = m['account_number'] ?? '';

                    // Find the active loan for this member
                    final memberDriverId = m['driver_id']?.toString();
                    Map<String, dynamic>? memberLoan;
                    for (final l in _allSaccoLoans) {
                      if (l['driver_id']?.toString() == memberDriverId &&
                          (l['status'] ?? '').toString().toLowerCase() == 'approved') {
                        memberLoan = l;
                        break;
                      }
                    }
                    final loanAmount = memberLoan != null ? double.tryParse(memberLoan['amount_tsh'].toString()) ?? 0.0 : 0.0;
                    final repaidAmount = memberLoan != null ? double.tryParse((memberLoan['total_repaid'] ?? '0').toString()) ?? 0.0 : 0.0;
                    final remaining = loanAmount - repaidAmount;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColAccountId = m['account_id']?.toString();
                          _colMemberSearchController.clear();
                          // Auto-fill remaining balance
                          _colAmountController.text = remaining > 0 ? remaining.toStringAsFixed(0) : '';
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.navy.withOpacity(0.1),
                              radius: 20,
                              child: Text(
                                name.toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navy)),
                                  const SizedBox(height: 2),
                                  Text('$phone | $plate | $acctNo', style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TSh ${remaining.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: remaining > 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                                Text(
                                  lang.locale == 'en' ? 'remaining' : 'imebaki',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.gray),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],

          // Selected member card + payment form
          if (_selectedColAccountId != null && selectedMember != null) ...[
            Card(
              elevation: 2,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.person, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedMember['full_name'] ?? 'Driver',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                              ),
                              Text(
                                '${selectedMember['phone'] ?? ''} | ${selectedMember['account_number'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: lang.locale == 'en' ? 'Change Member' : 'Badilisha Mwanachama',
                          onPressed: () {
                            setState(() {
                              _selectedColAccountId = null;
                            });
                          },
                        ),
                      ],
                    ),
                    if (selectedLoan != null) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLoanInfoChip(
                            lang.locale == 'en' ? 'Loan' : 'Mkopo',
                            'TSh ${double.parse(selectedLoan['amount_tsh'].toString()).toStringAsFixed(0)}',
                            Colors.blue,
                          ),
                          _buildLoanInfoChip(
                            lang.locale == 'en' ? 'Repaid' : 'Amelipa',
                            'TSh ${double.tryParse((selectedLoan['total_repaid'] ?? '0').toString())?.toStringAsFixed(0) ?? '0'}',
                            Colors.green,
                          ),
                          _buildLoanInfoChip(
                            lang.locale == 'en' ? 'Remaining' : 'Imebaki',
                            'TSh ${(double.parse(selectedLoan['amount_tsh'].toString()) - (double.tryParse((selectedLoan['total_repaid'] ?? '0').toString()) ?? 0)).toStringAsFixed(0)}',
                            Colors.red,
                          ),
                        ],
                      ),
                      if (selectedLoan['missed_payments_count'] != null && (selectedLoan['missed_payments_count'] as num) > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: Colors.red, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${lang.locale == "en" ? "Missed days" : "Siku zilizokosekana"}: ${selectedLoan['missed_payments_count']}',
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overpayment warning
            Builder(builder: (context) {
              final enteredAmt = double.tryParse(_colAmountController.text.trim()) ?? 0.0;
              final remainingAmt = selectedLoan != null
                  ? (double.parse(selectedLoan['amount_tsh'].toString()) - (double.tryParse((selectedLoan['total_repaid'] ?? '0').toString()) ?? 0))
                  : 0.0;
              if (enteredAmt > remainingAmt && remainingAmt > 0) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lang.locale == 'en'
                              ? 'Payment amount (TSh ${enteredAmt.toStringAsFixed(0)}) is greater than remaining balance (TSh ${remainingAmt.toStringAsFixed(0)}).'
                              : 'Kiasi cha malipo (TSh ${enteredAmt.toStringAsFixed(0)}) ni zaidi ya salio lililobaki (TSh ${remainingAmt.toStringAsFixed(0)}).',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Payment form
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Amount
                    TextField(
                      controller: _colAmountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: lang.locale == 'en' ? 'Repayment Amount (TSh)' : 'Kiasi cha Malipo (TSh)',
                        prefixText: 'TSh ',
                        helperText: selectedLoan != null
                            ? '${lang.locale == "en" ? "Remaining" : "Imebaki"}: TSh ${(double.parse(selectedLoan['amount_tsh'].toString()) - (double.tryParse((selectedLoan['total_repaid'] ?? '0').toString()) ?? 0)).toStringAsFixed(0)}'
                            : null,
                        helperStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Method Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedColMethod,
                      decoration: InputDecoration(
                        labelText: lang.locale == 'en' ? 'Payment Method' : 'Njia ya Malipo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: methods.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['val'],
                          child: Text(m['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedColMethod = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Reference (Optional)
                    TextField(
                      controller: _colReferenceController,
                      decoration: InputDecoration(
                        labelText: lang.locale == 'en' ? 'Reference / Receipt (Optional)' : 'Namba ya Muamala (Si Lazima)',
                        hintText: 'e.g. PP240612...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: _savingCollection
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _savingCollection
                              ? (lang.locale == 'en' ? 'Recording...' : 'Inarekodi...')
                              : (lang.locale == 'en' ? 'Record Repayment' : 'Rekodi Malipo'),
                        ),
                        onPressed: _savingCollection
                            ? null
                            : () async {
                                final amt = double.tryParse(_colAmountController.text.trim()) ?? 0.0;
                                if (amt <= 0) {
                                  _showSnackbar(
                                    lang.locale == 'en' ? 'Please enter a valid amount' : 'Tafadhali weka kiasi sahihi',
                                    Colors.red,
                                  );
                                  return;
                                }
                                setState(() => _savingCollection = true);
                                try {
                                  await _api.post('/sacco/collections', body: {
                                    'sacco_account_id': _selectedColAccountId,
                                    'amount_tsh': amt,
                                    'collection_method': _selectedColMethod,
                                    'reference': _colReferenceController.text.trim(),
                                  });
                                  _showSnackbar(
                                    lang.locale == 'en' ? 'Repayment recorded successfully!' : 'Malipo yamerekodiwa kikamilifu!',
                                    Colors.green,
                                  );
                                  _colAmountController.clear();
                                  _colReferenceController.clear();
                                  setState(() {
                                    _selectedColAccountId = null;
                                  });
                                  _loadCollections();
                                  _loadOverview();
                                  _loadAllSaccoLoans();
                                } catch (e) {
                                  _showSnackbar(e.toString(), Colors.red);
                                } finally {
                                  setState(() => _savingCollection = false);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            lang.locale == 'en' ? 'Repayment History' : 'Historia ya Malipo',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
          const SizedBox(height: 12),
          _buildCollectionsList(lang),
        ],
      ),
    );
  }

  Widget _buildLoanInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCollectionsList(LanguageProvider lang, {int? limit}) {
    if (_loadingCollections) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = (limit != null && _collections.length > limit)
        ? _collections.sublist(0, limit)
        : _collections;

    if (list.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              lang.locale == 'en' ? 'No recent collections logged.' : 'Hakuna makusanyo yaliyorekodiwa karibuni.',
              style: const TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final c = list[i];
        final driverName = c['driver_name'] ?? 'Member';
        final acct = c['account_number'] ?? '';
        final amount = c['amount_tsh'] != null ? double.parse(c['amount_tsh'].toString()) : 0.0;
        final method = c['collection_method'] ?? 'cash';
        final date = c['collected_at'] != null ? DateTime.parse(c['collected_at']).toLocal().toString().substring(0, 16) : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(Icons.arrow_downward, color: Colors.green),
            ),
            title: Text(
              '$driverName ($acct)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              'Method: ${method.toUpperCase()} | $date',
              style: const TextStyle(fontSize: 11, color: AppTheme.gray),
            ),
            trailing: Text(
              '+ TSh ${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: SACCO LOAN REQUESTS
  // ==========================================
  Widget _buildLoansTab(LanguageProvider lang) {
    final filters = [
      {'val': 'all', 'label': lang.locale == 'en' ? 'All' : 'Zote'},
      {'val': 'pending', 'label': lang.locale == 'en' ? 'Pending' : 'Zinasubiri'},
      {'val': 'approved', 'label': lang.locale == 'en' ? 'Active' : 'Hai'},
      {'val': 'repaid', 'label': lang.locale == 'en' ? 'Repaid' : 'Zilizolipwa'},
      {'val': 'denied', 'label': lang.locale == 'en' ? 'Denied' : 'Zilizokataliwa'},
    ];

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'approved':
        case 'active':
          return Colors.green;
        case 'repaid':
          return Colors.blue;
        case 'denied':
        case 'rejected':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Column(
      children: [
        // Search & Autocomplete
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _loanSearchController,
            onChanged: (val) {
              if (_loanDebounceTimer?.isActive ?? false) _loanDebounceTimer?.cancel();
              _loanDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                _loadSaccoLoans();
              });
            },
            decoration: InputDecoration(
              labelText: lang.translate('search_system_drivers_hint') ?? 'Search by Name/Phone/ID',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),

        // Filter Chips
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filters.length,
            itemBuilder: (context, idx) {
              final filter = filters[idx];
              final isSelected = _selectedLoanFilter == filter['val'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(
                    filter['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.navy,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.navy,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLoanFilter = filter['val']!;
                    });
                    _loadSaccoLoans();
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),

        // List
        Expanded(
          child: _loadingLoans
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadPendingLoans();
                    await _loadSaccoLoans();
                  },
                  child: _saccoLoans.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Text(
                                lang.locale == 'en' ? 'No Sacco loans found.' : 'Hakuna mikopo ya Sacco iliyopatikana.',
                                style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.gray),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _saccoLoans.length,
                          itemBuilder: (context, i) {
                            final l = _saccoLoans[i];
                            final loanId = l['id'];
                            final driverName = l['driver_name'] ?? 'Driver';
                            final phone = l['driver_phone'] ?? '';
                            final score = (l['score'] as num?)?.toDouble() ?? 0.0;
                            final tier = l['tier'] as String? ?? 'unranked';
                            final amount = double.parse(l['amount_tsh'].toString());
                            final purpose = l['loan_purpose'] ?? 'fuel';
                            final status = l['status'] ?? 'pending';
                            final missedCount = l['missed_payments_count'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => SaccoLoanDetailScreen(loanId: loanId)),
                                  ).then((_) {
                                    _loadSaccoLoans();
                                    _loadPendingLoans();
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            driverName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(status).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status.toString().toUpperCase(),
                                              style: TextStyle(
                                                color: getStatusColor(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${lang.locale == "en" ? "Phone" : "Simu"}: $phone', style: const TextStyle(color: AppTheme.gray, fontSize: 12)),
                                          Text(
                                            '${lang.translate("boda_score")}: ${score.toStringAsFixed(0)} (${tier.toUpperCase()})',
                                            style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${lang.translate("loan_purpose_label")}: ${purpose.toString().toUpperCase()}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            'TSh ${amount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navy),
                                          ),
                                        ],
                                      ),
                                      if (missedCount > 0) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.warning, color: Colors.red, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${lang.translate("missed_payments")}: $missedCount',
                                                style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }


  Widget _buildStandardsTab(LanguageProvider lang) {
    if (_loadingStandards) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.translate('update_standards') ?? 'Update Sacco Standards',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _minBodaScoreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.translate('min_boda_score') ?? 'Min Boda Score',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _minSavingsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.translate('min_savings_balance_tsh') ?? 'Min Savings Balance (TSh)',
                      prefixText: 'TSh ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _multiplierController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: lang.translate('max_loan_limit_multiplier') ?? 'Loan Limit Multiplier (e.g. 3x savings)',
                      suffixText: 'x',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _saveStandards(lang),
                      child: Text(lang.translate('submit') ?? 'Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
