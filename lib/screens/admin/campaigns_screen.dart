import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleEnController = TextEditingController();
  final _titleSwController = TextEditingController();
  final _msgEnController = TextEditingController();
  final _msgSwController = TextEditingController();
  
  String _selectedTarget = 'drivers';
  bool _sending = false;

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
    _titleEnController.dispose();
    _titleSwController.dispose();
    _msgEnController.dispose();
    _msgSwController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _sendCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _sending = true);
    try {
      await _api.post('/admin/campaigns', body: {
        'target': _selectedTarget,
        'title': _titleEnController.text.trim(),
        'title_sw': _titleSwController.text.trim(),
        'message': _msgEnController.text.trim(),
        'message_sw': _msgSwController.text.trim(),
      });
      
      _titleEnController.clear();
      _titleSwController.clear();
      _msgEnController.clear();
      _msgSwController.clear();
      
      _showSnackbar('Campaign broadcast sent successfully!', Colors.green);
    } catch (e) {
      _showSnackbar(e.toString(), Colors.red);
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.campaign, color: AppTheme.gold, size: 36),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Notification Campaign',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navy,
                                  ),
                            ),
                            Text(
                              'Broadcast push notifications to all users on the platform.',
                              style: TextStyle(color: AppTheme.gray, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // Target Dropdown
                    Text(
                      'Target Group',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTarget,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.group, color: AppTheme.navy),
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'drivers', child: Text('All Drivers')),
                        DropdownMenuItem(value: 'saccos', child: Text('All Sacco Admins')),
                        DropdownMenuItem(value: 'all', child: Text('All System Users')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTarget = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // English Fields Group
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Text('English Content', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleEnController,
                            decoration: const InputDecoration(
                              labelText: 'Notification Title (EN)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _msgEnController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Message Body (EN)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Message is required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Swahili Fields Group
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text('Swahili Content (Kiswahili)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleSwController,
                            decoration: const InputDecoration(
                              labelText: 'Kichwa cha Taarifa (SW)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Kichwa kinahitajika' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _msgSwController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Mwili wa Ujumbe (SW)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ujumbe unahitajika' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _sending ? null : _sendCampaign,
                        child: _sending
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send Broadcast Campaign',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
