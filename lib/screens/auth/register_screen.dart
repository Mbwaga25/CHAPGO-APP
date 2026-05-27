import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

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

  bool _isValidPhone(String phone) => RegExp(r'^\+255\d{9}$').hasMatch(phone);
  bool _isValidNida(String nida) => RegExp(r'^\d{20}$').hasMatch(nida);
  bool _isValidPlate(String plate) => RegExp(r'^T\d{3}[A-Za-z]{3}$').hasMatch(plate.toUpperCase());

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (!_isValidPhone(phone)) {
      _showError('Namba ya simu si sahihi. Mfano: +255712345678');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(phone, purpose: 'registration');
    if (mounted && ok) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP imetumwa kwa namba yako')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'OTP haikutumwa. Tafadhali jaribu tena.')),
      );
    }
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final nida = _nidaController.text.trim();
    final plate = _plateController.text.trim().toUpperCase();
    final password = _passwordController.text;
    final otp = _otpController.text.trim();

    if (!_isValidPhone(phone)) { _showError('Namba ya simu si sahihi'); return; }
    if (name.length < 3) { _showError('Jina lazima iwe angalau herufi 3'); return; }
    if (!_isValidNida(nida)) { _showError('NIDA ina tarakimu 20'); return; }
    if (!_isValidPlate(plate)) { _showError('Namba ya gari: T123ABC'); return; }
    if (password.length < 6) { _showError('Nenosiri lazima liwe na angalau herufi 6'); return; }
    if (!_consentGiven) { _showError('Tafadhali kubali masharti ya usindikaji wa data'); return; }

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

    if (mounted && success) {
      Navigator.pushNamedAndRemoveUntil(context, '/driver/home', (_) => false);
    } else if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Usajili umeshindikana')),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sajili')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('Unda akaunti ya Driver', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const SizedBox(height: 4),
            Text('Jaza taarifa zako hapa chini', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
            const SizedBox(height: 24),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Namba ya simu', hintText: '+255712345678'),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Jina kamili', hintText: 'John Doe'),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _nidaController,
              keyboardType: TextInputType.number,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Namba ya NIDA (tarakimu 20)',
                hintText: '19700101000000000000',
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Namba ya gari', hintText: 'T123ABC'),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nenosiri (Tengeneza password)', hintText: '••••••••'),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _vehicleType,
              decoration: const InputDecoration(labelText: 'Aina ya gari'),
              items: const [
                DropdownMenuItem(value: 'bodaboda', child: Text('Bodaboda')),
                DropdownMenuItem(value: 'bajaji', child: Text('Bajaji')),
                DropdownMenuItem(value: 'small_truck', child: Text('Small Truck')),
              ],
              onChanged: (v) => setState(() => _vehicleType = v ?? 'bodaboda'),
            ),
            const SizedBox(height: 20),

            CheckboxListTile(
                value: _consentGiven,
                onChanged: (v) => setState(() => _consentGiven = v ?? false),
                title: Text(
                  'Nakubali usindikaji wa data yangu binafsi kwa mujibu wa sera ya faragha ya Chapgo',
                  style: TextStyle(fontSize: 13, color: AppTheme.navy),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                      : const Text('Sajili'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
