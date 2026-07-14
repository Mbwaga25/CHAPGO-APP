import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/image_picker_stub.dart'
    if (dart.library.html) '../../widgets/image_picker_web.dart' as picker;
import '../../widgets/driver_subpage_navbar.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _profileData = {};

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _nidaController = TextEditingController();
  final _passportController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _plateController = TextEditingController();
  
  String _selectedVehicleType = 'bodaboda';
  List<int>? _pickedImageBytes;
  String? _pickedImageName;

  List<dynamic> _saccos = [];
  String? _selectedSaccoId;

  void _onDistrictChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _api.setToken(user.token);
    }
    _districtController.addListener(_onDistrictChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _districtController.removeListener(_onDistrictChanged);
    _nameController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _nidaController.dispose();
    _passportController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _addressController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/driver/profile');
      setState(() {
        _profileData = data;
        _nameController.text = data['full_name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _districtController.text = data['district'] ?? '';
        _wardController.text = data['ward'] ?? '';
        _nidaController.text = data['nida_number'] ?? '';
        _passportController.text = data['passport_number'] ?? '';
        _emergencyNameController.text = data['emergency_contact_name'] ?? '';
        _emergencyPhoneController.text = data['emergency_contact_phone'] ?? '';
        _addressController.text = data['residential_address'] ?? '';
        _plateController.text = data['vehicle_plate'] ?? '';
        _selectedVehicleType = data['vehicle_type'] ?? 'bodaboda';
        _selectedSaccoId = data['sacco_id'];
      });
      await _loadSaccos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSaccos() async {
    try {
      final res = await _api.get('/driver/saccos');
      if (res != null && res['saccos'] != null) {
        setState(() {
          _saccos = res['saccos'] as List<dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Failed to load Saccos: $e');
    }
  }

  List<dynamic> _getSortedSaccos() {
    final district = _districtController.text.trim().toLowerCase();
    if (district.isEmpty) return _saccos;

    final sorted = List<dynamic>.from(_saccos);
    sorted.sort((a, b) {
      final districtA = (a['district'] ?? '').toString().toLowerCase();
      final districtB = (b['district'] ?? '').toString().toLowerCase();
      
      final isMatchA = districtA == district;
      final isMatchB = districtB == district;
      
      if (isMatchA && !isMatchB) return -1;
      if (!isMatchA && isMatchB) return 1;
      
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });
    return sorted;
  }

  Future<void> _pickPhoto() async {
    try {
      final res = await picker.pickImage();
      if (res != null) {
        setState(() {
          _pickedImageBytes = res['bytes'] as List<int>;
          _pickedImageName = res['name'] as String;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();

    final Map<String, String> fields = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'district': _districtController.text.trim(),
      'ward': _wardController.text.trim(),
      'nida_number': _nidaController.text.trim(),
      'passport_number': _passportController.text.trim(),
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_contact_phone': _emergencyPhoneController.text.trim(),
      'residential_address': _addressController.text.trim(),
      'vehicle_plate': _plateController.text.trim(),
      'vehicle_type': _selectedVehicleType,
      'sacco_id': _selectedSaccoId ?? '',
    };

    final success = await auth.updateDriverProfile(
      fields: fields,
      fileBytes: _pickedImageBytes,
      fileName: _pickedImageName,
    );

    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('success')), backgroundColor: Colors.green),
      );
      _pickedImageBytes = null;
      _pickedImageName = null;
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final user = context.watch<AuthProvider>().user;

    String? dbImgUrl = _profileData['profile_image_url'];
    String rootUrl = ApiConfig.apiBase.replaceAll('/api/v1', '');
    String? fullImageUrl = dbImgUrl != null ? '$rootUrl$dbImgUrl' : null;

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('profile'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Photo selector avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AppTheme.green,
                            backgroundImage: _pickedImageBytes != null
                                ? MemoryImage(Uint8List.fromList(_pickedImageBytes!)) as ImageProvider
                                : (fullImageUrl != null ? NetworkImage(fullImageUrl) as ImageProvider : null),
                            child: _pickedImageBytes == null && fullImageUrl == null
                                ? Text(
                                    user?.initials ?? 'D',
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.gold,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                onPressed: _pickPhoto,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Forms
                    _buildSectionHeader(lang.translate('personal_info')),
                    _buildTextField(
                      controller: _nameController,
                      label: lang.translate('full_name_field'),
                      validator: (v) => v == null || v.trim().length < 3 ? lang.translate('name_min_chars') : null,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _districtController,
                      label: 'District / Wilaya',
                    ),
                    _buildTextField(
                      controller: _wardController,
                      label: 'Ward / Kata',
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader(lang.translate('verification_details')),
                    _buildTextField(
                      controller: _nidaController,
                      label: lang.translate('nida_field'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty && v.trim().length != 20) {
                          return lang.translate('nida_digit_count');
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _passportController,
                      label: lang.translate('passport_number_field'),
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: lang.translate('residential_address_field'),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Emergency Contact / Dharura'),
                    _buildTextField(
                      controller: _emergencyNameController,
                      label: lang.translate('emergency_contact_name_field'),
                    ),
                    _buildTextField(
                      controller: _emergencyPhoneController,
                      label: lang.translate('emergency_contact_phone_field'),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader(lang.translate('vehicle_info')),
                    _buildTextField(
                      controller: _plateController,
                      label: lang.translate('plate_field'),
                      hint: 'e.g. T123ABC',
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final reg = RegExp(r'^T\d{3}[A-Z]{3}$', caseSensitive: false);
                          if (!reg.hasMatch(v.trim())) {
                            return lang.translate('plate_invalid');
                          }
                        }
                        return null;
                      },
                    ),
                    _buildDropdownField(lang),

                    const SizedBox(height: 16),
                    _buildSectionHeader(lang.translate('sacco_membership')),
                    _buildSaccoDropdownField(lang),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                lang.translate('submit').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const DriverSubPageNavBar(activeIndex: 5),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.gray),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.grayLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.navy, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField(LanguageProvider lang) {
    final types = ['bodaboda', 'bajaji', 'small_truck'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedVehicleType,
        items: types.map((t) => DropdownMenuItem(value: t, child: Text(lang.translate(t)))).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedVehicleType = val);
        },
        decoration: InputDecoration(
          labelText: lang.translate('vehicle_type_field'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSaccoDropdownField(LanguageProvider lang) {
    final sortedSaccos = _getSortedSaccos();
    final hasSelected = _selectedSaccoId != null && 
        sortedSaccos.any((s) => s['id'] == _selectedSaccoId);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String?>(
        value: hasSelected ? _selectedSaccoId : null,
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(lang.translate('no_sacco_assigned')),
          ),
          ...sortedSaccos.map((s) {
            String name = s['name'] ?? '';
            final sDistrict = s['district'] ?? '';
            if (sDistrict.isNotEmpty) {
              name += ' ($sDistrict)';
            }
            final driverDistrict = _districtController.text.trim().toLowerCase();
            if (driverDistrict.isNotEmpty && sDistrict.toLowerCase() == driverDistrict) {
              name += ' - ${lang.translate('near_you')}';
            }
            return DropdownMenuItem<String?>(
              value: s['id'],
              child: Text(name),
            );
          }).toList(),
        ],
        onChanged: (val) {
          setState(() => _selectedSaccoId = val);
        },
        decoration: InputDecoration(
          labelText: lang.translate('sacco_select'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
