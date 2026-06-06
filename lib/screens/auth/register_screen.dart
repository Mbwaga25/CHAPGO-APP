import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _nidaController = TextEditingController();
  final _plateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  String _vehicleType = 'bodaboda';
  bool _consentGiven = false;
  bool _otpSent = false;
  bool _submitting = false;

  String _selectedCountryCode = '+255';

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _nidaController.dispose();
    _plateController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    String raw = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) return '';
    if (raw.startsWith('+')) return raw;
    String codeDigits = _selectedCountryCode.replaceFirst('+', '');
    if (raw.startsWith(codeDigits)) return '+$raw';
    if (raw.startsWith('0')) return _selectedCountryCode + raw.substring(1);
    return _selectedCountryCode + raw;
  }

  bool _isValidPhone(String phone) {
    if (phone.startsWith('+255')) {
      return RegExp(r'^\+255\d{9}$').hasMatch(phone);
    }
    return RegExp(r'^\+\d{10,14}$').hasMatch(phone);
  }

  bool _isValidNida(String nida) => RegExp(r'^\d{20}$').hasMatch(nida);
  bool _isValidPlate(String plate) => RegExp(r'^T\d{3}[A-Za-z]{3}$').hasMatch(plate.toUpperCase());

  void _sendOtp() async {
    final lang = context.read<LanguageProvider>();
    final name = _nameController.text.trim();
    if (name.length < 3) {
      _showNotification(lang.translate('name_min_chars'), type: 'warning');
      return;
    }

    final phone = _normalizedPhone;
    if (!_isValidPhone(phone)) {
      _showNotification(lang.translate('invalid_phone'), type: 'error');
      return;
    }

    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(phone, purpose: 'registration');
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        setState(() => _otpSent = true);
        _showNotification(lang.translate('otp_sent_success'), type: 'success');
      } else {
        _showNotification(auth.error ?? lang.translate('error'), type: 'error');
      }
    }
  }

  Future<void> _submit() async {
    final lang = context.read<LanguageProvider>();
    final phone = _normalizedPhone;
    final name = _nameController.text.trim();
    final nida = _nidaController.text.trim();
    final plate = _plateController.text.trim().toUpperCase();
    final password = _passwordController.text;
    final otp = _otpController.text.trim();

    if (!_isValidPhone(phone)) { _showNotification(lang.translate('invalid_phone'), type: 'error'); return; }
    if (name.length < 3) { _showNotification(lang.translate('name_min_chars'), type: 'warning'); return; }
    if (otp.length != 6) { _showNotification(lang.translate('otp_digit_count'), type: 'warning'); return; }
    if (nida.isNotEmpty && !_isValidNida(nida)) { _showNotification(lang.translate('nida_digit_count'), type: 'error'); return; }
    if (plate.isNotEmpty && !_isValidPlate(plate)) { _showNotification(lang.translate('plate_invalid'), type: 'error'); return; }
    if (password.length < 6) { _showNotification(lang.translate('password_min_chars'), type: 'warning'); return; }
    if (!_consentGiven) { _showNotification(lang.translate('consent_warning'), type: 'warning'); return; }

    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.registerDriver(
      phone: phone,
      password: password,
      fullName: name,
      nidaNumber: nida,
      otpCode: otp,
      vehiclePlate: plate,
      vehicleType: _vehicleType,
      consentToDataProcessing: _consentGiven,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        _showNotification(lang.translate('register_success'), type: 'success');
        Navigator.pushNamedAndRemoveUntil(context, '/driver/home', (_) => false);
      } else {
        _showNotification(auth.error ?? lang.translate('register_failed'), type: 'error');
      }
    }
  }

  void _showNotification(String message, {String type = 'success'}) {
    Color bgColor;
    IconData icon;
    switch (type) {
      case 'success':
        bgColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        break;
      case 'error':
        bgColor = Colors.red.shade600;
        icon = Icons.error_outline;
        break;
      case 'warning':
        bgColor = Colors.orange.shade700;
        icon = Icons.warning_amber_outlined;
        break;
      default:
        bgColor = Colors.blue.shade600;
        icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 90,
          left: 15,
          right: 15,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('register_title'))),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(lang.translate('register_heading'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text(lang.translate('register_subheading'), style: const TextStyle(fontSize: 14, color: AppTheme.gray)),
                const SizedBox(height: 24),

                // Jina kamili field (First Step)
                TextField(
                  controller: _nameController,
                  enabled: !_otpSent,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: lang.translate('full_name_field'), hintText: 'John Doe'),
                ),
                const SizedBox(height: 14),

                // Country Selector and Phone field row (First Step)
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
                          value: _selectedCountryCode,
                          items: const [
                            DropdownMenuItem(value: '+255', child: Text('🇹🇿 +255')),
                            DropdownMenuItem(value: '+254', child: Text('🇰🇪 +254')),
                            DropdownMenuItem(value: '+256', child: Text('🇺🇬 +256')),
                            DropdownMenuItem(value: '+250', child: Text('🇷🇼 +250')),
                          ],
                          onChanged: _otpSent ? null : (v) {
                            setState(() {
                              _selectedCountryCode = v ?? '+255';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        enabled: !_otpSent,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: lang.translate('phone_field'), hintText: lang.translate('phone_hint')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (!_otpSent) ...[
                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _sendOtp,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                          : Text(lang.translate('send_otp_btn')),
                    ),
                  ),
                ] else ...[
                  // Option to edit name and phone if OTP was sent
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _otpSent = false;
                          });
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(lang.translate('change_phone_name')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // OTP Input field (Step 2)
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: lang.translate('otp_digit_count'),
                      hintText: '123456',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // NIDA Input field (Step 2)
                  TextField(
                    controller: _nidaController,
                    keyboardType: TextInputType.number,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: '${lang.translate('nida_field')} (${lang.translate('optional_label')})',
                      hintText: '19700101000000000000',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Plate Number field (Step 2)
                  TextField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: '${lang.translate('plate_field')} (${lang.translate('optional_label')})',
                      hintText: 'T123ABC',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password field (Step 2)
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: lang.translate('password_create_field'), hintText: '••••••••'),
                  ),
                  const SizedBox(height: 14),

                  // Vehicle Type dropdown field (Step 2)
                  DropdownButtonFormField<String>(
                    value: _vehicleType,
                    decoration: InputDecoration(
                      labelText: '${lang.translate('vehicle_type_field')} (${lang.translate('optional_label')})',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bodaboda', child: Text('Bodaboda')),
                      DropdownMenuItem(value: 'bajaji', child: Text('Bajaji')),
                      DropdownMenuItem(value: 'small_truck', child: Text('Small Truck')),
                    ],
                    onChanged: (v) => setState(() => _vehicleType = v ?? 'bodaboda'),
                  ),
                  const SizedBox(height: 20),

                  // Consent Checkbox (Step 2)
                  CheckboxListTile(
                    value: _consentGiven,
                    onChanged: (v) => setState(() => _consentGiven = v ?? false),
                    title: Text(
                      lang.translate('consent_checkbox'),
                      style: const TextStyle(fontSize: 13, color: AppTheme.navy),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  // Submit Button (Step 2)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                          : Text(lang.translate('register_btn')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
