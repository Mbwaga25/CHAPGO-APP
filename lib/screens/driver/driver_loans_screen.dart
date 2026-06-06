import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/driver_subpage_navbar.dart';

class DriverLoansScreen extends StatefulWidget {
  const DriverLoansScreen({super.key});

  @override
  State<DriverLoansScreen> createState() => _DriverLoansScreenState();
}

class _DriverLoansScreenState extends State<DriverLoansScreen> {
  final _api = ApiService();
  final _amountController = TextEditingController();
  final _termController = TextEditingController(text: '3');
  final _otpController = TextEditingController();

  // New Loan KYC controllers
  final _nidaController = TextEditingController();
  final _passportController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _customDaysController = TextEditingController();

  String _selectedPurpose = 'fuel';
  String _selectedBank = 'sacco_internal';
  String _selectedFrequency = 'monthly';
  bool _otpSent = false;
  bool _submitting = false;
  bool _loadingProfile = true;

  // Sacco specific state variables
  String? _saccoId;
  String? _saccoName;
  double? _saccoBalance;
  double? _saccoMultiplier;
  double? _maxSaccoLoanLimit;
  int? _saccoMinScore;
  double? _saccoMinSavings;
  int? _driverScore;

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadProfile();
  }

  void _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) _api.setToken(user.token);
      final profile = await _api.get('/driver/profile');
      if (mounted) {
        setState(() {
          _nidaController.text = profile['nida_number'] as String? ?? '';
          _passportController.text = profile['passport_number'] as String? ?? '';
          _emergencyNameController.text = profile['emergency_contact_name'] as String? ?? '';
          _emergencyPhoneController.text = profile['emergency_contact_phone'] as String? ?? '';
          _addressController.text = profile['residential_address'] as String? ?? '';

          _saccoId = profile['sacco_id'] as String?;
          _saccoName = profile['sacco_name'] as String?;
          
          if (profile['sacco_balance_tsh'] != null) {
            _saccoBalance = double.tryParse(profile['sacco_balance_tsh'].toString());
          } else {
            _saccoBalance = null;
          }
          if (profile['sacco_max_loan_limit_multiplier'] != null) {
            _saccoMultiplier = double.tryParse(profile['sacco_max_loan_limit_multiplier'].toString());
          } else {
            _saccoMultiplier = null;
          }
          if (_saccoBalance != null && _saccoMultiplier != null) {
            _maxSaccoLoanLimit = _saccoBalance! * _saccoMultiplier!;
          } else {
            _maxSaccoLoanLimit = null;
          }
          
          if (profile['sacco_min_boda_score'] != null) {
            _saccoMinScore = int.tryParse(profile['sacco_min_boda_score'].toString());
          } else {
            _saccoMinScore = null;
          }
          if (profile['sacco_min_savings_balance_tsh'] != null) {
            _saccoMinSavings = double.tryParse(profile['sacco_min_savings_balance_tsh'].toString());
          } else {
            _saccoMinSavings = null;
          }
          if (profile['score'] != null) {
            _driverScore = int.tryParse(profile['score'].toString());
          } else {
            _driverScore = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile details: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _termController.dispose();
    _otpController.dispose();
    _nidaController.dispose();
    _passportController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _addressController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  void _sendOtp(String phone, LanguageProvider lang) async {
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(phone, purpose: 'financial_action');
    setState(() => _submitting = false);

    if (mounted) {
      if (ok) {
        setState(() => _otpSent = true);
        _showNotification(lang.translate('otp_sent_msg'), type: 'success');
      } else {
        _showNotification(auth.error ?? lang.translate('error'), type: 'error');
      }
    }
  }

  void _submitApplication(String phone, LanguageProvider lang) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final term = int.tryParse(_termController.text.trim()) ?? 0;
    final otp = _otpController.text.trim();

    final nida = _nidaController.text.trim();
    final passport = _passportController.text.trim();
    final emName = _emergencyNameController.text.trim();
    final emPhone = _emergencyPhoneController.text.trim();
    final address = _addressController.text.trim();

    if (amount <= 0) {
      _showNotification(lang.locale == 'en' ? 'Please enter a valid loan amount' : 'Tafadhali weka kiasi halali cha mkopo', type: 'warning');
      return;
    }
    if (_selectedBank == 'sacco_internal') {
      if (_saccoId == null) {
        _showNotification(
          lang.locale == 'en' 
              ? 'You must belong to a SACCO to apply for an internal SACCO loan' 
              : 'Lazima ujiunge na SACCO ili kuomba mkopo wa ndani wa SACCO', 
          type: 'warning',
        );
        return;
      }
      if (_saccoMinScore != null && _driverScore != null && _driverScore! < _saccoMinScore!) {
        _showNotification(
          lang.locale == 'en'
              ? 'Your Boda Score ($_driverScore) is below the SACCO minimum required score of $_saccoMinScore'
              : 'Score yako ya Boda ($_driverScore) iko chini ya kiwango cha chini cha SACCO cha $_saccoMinScore',
          type: 'warning',
        );
        return;
      }
      if (_saccoMinSavings != null && _saccoBalance != null && _saccoBalance! < _saccoMinSavings!) {
        _showNotification(
          lang.locale == 'en'
              ? 'Your SACCO savings balance (TSh ${_formatCurrency(_saccoBalance!)}) is below the required minimum of TSh ${_formatCurrency(_saccoMinSavings!)}'
              : 'Akiba yako ya SACCO (TSh ${_formatCurrency(_saccoBalance!)}) iko chini ya kiwango cha chini cha TSh ${_formatCurrency(_saccoMinSavings!)}',
          type: 'warning',
        );
        return;
      }
      if (_maxSaccoLoanLimit != null && amount > _maxSaccoLoanLimit!) {
        _showNotification(
          lang.locale == 'en'
              ? 'Requested loan amount exceeds your maximum SACCO loan limit of TSh ${_formatCurrency(_maxSaccoLoanLimit!)}'
              : 'Kiasi cha mkopo unachoomba kinazidi kikomo cha mkopo wa SACCO cha TSh ${_formatCurrency(_maxSaccoLoanLimit!)}',
          type: 'warning',
        );
        return;
      }
    }
    if (term <= 0) {
      _showNotification(lang.locale == 'en' ? 'Please enter a valid term in months' : 'Tafadhali weka muda halali wa miezi', type: 'warning');
      return;
    }
    if (nida.length != 20 || !RegExp(r'^\d{20}$').hasMatch(nida)) {
      _showNotification(lang.locale == 'en' ? 'Please enter a valid 20-digit NIDA number' : 'Tafadhali weka namba halali ya NIDA yenye tarakimu 20', type: 'warning');
      return;
    }
    if (passport.length < 5) {
      _showNotification(lang.locale == 'en' ? 'Please enter a valid passport number' : 'Tafadhali weka namba halali ya pasipoti', type: 'warning');
      return;
    }
    if (emName.length < 3) {
      _showNotification(lang.locale == 'en' ? 'Please enter emergency contact name' : 'Tafadhali weka jina la mwasiliani wa dharura', type: 'warning');
      return;
    }
    if (!RegExp(r'^\+255\d{9}$').hasMatch(emPhone)) {
      _showNotification(lang.locale == 'en' ? 'Emergency phone must start with +255' : 'Namba ya mwasiliani lazima ianze na +255', type: 'warning');
      return;
    }
    if (address.length < 5) {
      _showNotification(lang.locale == 'en' ? 'Please enter a valid residential address' : 'Tafadhali weka anwani halali ya makazi', type: 'warning');
      return;
    }
    if (_selectedFrequency == 'custom') {
      final days = int.tryParse(_customDaysController.text.trim()) ?? 0;
      if (days <= 0) {
        _showNotification(lang.translate('enter_custom_days'), type: 'warning');
        return;
      }
    }
    if (otp.length != 6) {
      _showNotification(lang.translate('otp_digit_count'), type: 'warning');
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) _api.setToken(user.token);

      final payload = {
        'loan_purpose': _selectedPurpose,
        'amount_tsh': amount,
        'term_months': term,
        'bank_partner': _selectedBank,
        'phone': phone,
        'otp_code': otp,
        'nida_number': nida,
        'passport_number': passport,
        'emergency_contact_name': emName,
        'emergency_contact_phone': emPhone,
        'residential_address': address,
        'repayment_frequency': _selectedFrequency,
        'repayment_frequency_custom_days': _selectedFrequency == 'custom' ? int.tryParse(_customDaysController.text.trim()) : null,
      };

      await _api.post('/loans/apply', body: payload);

      if (mounted) {
        _showNotification(lang.translate('loan_applied_msg'), type: 'success');
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        _showNotification(e.toString(), type: 'error');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showNotification(String message, {String type = 'success'}) {
    Color bgColor = type == 'success' ? Colors.green.shade600 : (type == 'error' ? Colors.red.shade600 : Colors.orange.shade700);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final user = context.watch<AuthProvider>().user;
    final phone = user?.phone ?? '';
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final purposes = ['fuel', 'parts', 'vehicle', 'education', 'housing', 'business', 'emergency'];
    final banks = [
      {'value': 'sacco_internal', 'label': 'SACCO Internal'},
      {'value': 'crdb', 'label': 'CRDB Bank'},
      {'value': 'nmb', 'label': 'NMB Bank'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('apply_loan_btn'))),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.locale == 'en' ? 'New Loan Request' : 'Ombi la Mkopo Mpya',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.locale == 'en'
                      ? 'Fill in the loan details and sign with the OTP verification code.'
                      : 'Jaza maelezo ya mkopo na uthibitishe kwa namba ya uhakiki ya OTP.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.gray),
                ),
                const SizedBox(height: 24),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Loan Purpose
                        DropdownButtonFormField<String>(
                          value: _selectedPurpose,
                          decoration: InputDecoration(labelText: lang.translate('loan_purpose_field')),
                          items: purposes
                              .map((p) => DropdownMenuItem(value: p, child: Text(lang.translate(p))))
                              .toList(),
                          onChanged: _otpSent ? null : (v) => setState(() => _selectedPurpose = v ?? 'fuel'),
                        ),
                        const SizedBox(height: 16),

                        // Amount
                        TextField(
                          controller: _amountController,
                          enabled: !_otpSent,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.translate('amount'),
                            prefixText: 'TSh ',
                          ),
                        ),
                        if (_selectedBank == 'sacco_internal' && _maxSaccoLoanLimit != null) ...[
                          if (enteredAmount > _maxSaccoLoanLimit!) ...[
                            const SizedBox(height: 8),
                            Text(
                              lang.locale == 'en'
                                  ? 'Warning: Requested amount exceeds your maximum SACCO loan limit of TSh ${_formatCurrency(_maxSaccoLoanLimit!)}!'
                                  : 'Onyo: Kiasi ulichoweka kinazidi kikomo chako cha mkopo wa SACCO cha TSh ${_formatCurrency(_maxSaccoLoanLimit!)}!',
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),

                        // Term in Months
                        TextField(
                          controller: _termController,
                          enabled: !_otpSent,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.translate('loan_term_field'),
                            hintText: '3',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bank Partner
                        DropdownButtonFormField<String>(
                          value: _selectedBank,
                          decoration: InputDecoration(labelText: lang.translate('bank_partner_field')),
                          items: banks
                              .map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!)))
                              .toList(),
                          onChanged: _otpSent ? null : (v) => setState(() => _selectedBank = v ?? 'sacco_internal'),
                        ),
                        if (_selectedBank == 'sacco_internal') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _saccoId != null ? AppTheme.navy.withOpacity(0.05) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _saccoId != null ? AppTheme.navy.withOpacity(0.2) : Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _saccoId != null ? Icons.account_balance : Icons.warning,
                                      color: _saccoId != null ? AppTheme.navy : Colors.orange.shade800,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _saccoId != null 
                                            ? (_saccoName ?? 'SACCO Member')
                                            : (lang.locale == 'en' ? 'No SACCO Joined' : 'Hujajiunga na SACCO'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _saccoId != null ? AppTheme.navy : Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_saccoId != null) ...[
                                  const SizedBox(height: 10),
                                  _buildInfoRow(
                                    lang.locale == 'en' ? 'Savings Balance' : 'Akiba Yako',
                                    'TSh ${_formatCurrency(_saccoBalance ?? 0.0)}',
                                  ),
                                  _buildInfoRow(
                                    lang.locale == 'en' ? 'Borrowing Multiplier' : 'Kiwango cha Kuzidisha',
                                    '${_saccoMultiplier ?? 0.0}x',
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    lang.locale == 'en' ? 'Max Loan Limit' : 'Kikomo cha Mkopo',
                                    'TSh ${_formatCurrency(_maxSaccoLoanLimit ?? 0.0)}',
                                    isBold: true,
                                    valueColor: AppTheme.gold,
                                  ),
                                  if (_saccoMinScore != null && _driverScore != null) ...[
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      lang.locale == 'en' ? 'Sacco Min Boda Score' : 'Score ya Chini ya Sacco',
                                      '$_saccoMinScore (Your Score: $_driverScore)',
                                      valueColor: _driverScore! >= _saccoMinScore! ? Colors.green : Colors.red,
                                    ),
                                  ],
                                  if (_saccoMinSavings != null && _saccoBalance != null) ...[
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      lang.locale == 'en' ? 'Sacco Min Savings' : 'Akiba ya Chini ya Sacco',
                                      'TSh ${_formatCurrency(_saccoMinSavings!)}',
                                      valueColor: _saccoBalance! >= _saccoMinSavings! ? Colors.green : Colors.red,
                                    ),
                                  ],
                                ] else ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    lang.locale == 'en'
                                        ? 'To request an internal loan, you must join a SACCO first. Go to your Profile to select a SACCO.'
                                        : 'Ili kuomba mkopo wa ndani, lazima ujiunge na SACCO kwanza. Nenda kwenye Taarifa Zangu kuchagua SACCO.',
                                    style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Repayment Frequency
                        DropdownButtonFormField<String>(
                          value: _selectedFrequency,
                          decoration: InputDecoration(labelText: lang.translate('repayment_frequency')),
                          items: ['daily', 'weekly', 'monthly', 'custom']
                              .map((f) => DropdownMenuItem(value: f, child: Text(lang.translate(f))))
                              .toList(),
                          onChanged: _otpSent ? null : (v) => setState(() => _selectedFrequency = v ?? 'monthly'),
                        ),
                        if (_selectedFrequency == 'custom') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _customDaysController,
                            enabled: !_otpSent,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.translate('custom_days'),
                              hintText: 'e.g. 5',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lang.translate('verification_details'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
                            ),
                            if (_loadingProfile)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // NIDA Number
                        TextField(
                          controller: _nidaController,
                          enabled: !_otpSent && !_loadingProfile,
                          keyboardType: TextInputType.number,
                          maxLength: 20,
                          decoration: InputDecoration(
                            labelText: lang.translate('nida_field'),
                            hintText: '19700101000000000000',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Passport Number
                        TextField(
                          controller: _passportController,
                          enabled: !_otpSent && !_loadingProfile,
                          decoration: InputDecoration(
                            labelText: lang.translate('passport_number_field'),
                            hintText: lang.translate('passport_hint'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Emergency Contact Name
                        TextField(
                          controller: _emergencyNameController,
                          enabled: !_otpSent && !_loadingProfile,
                          decoration: InputDecoration(
                            labelText: lang.translate('emergency_contact_name_field'),
                            hintText: lang.translate('emergency_name_hint'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Emergency Contact Phone
                        TextField(
                          controller: _emergencyPhoneController,
                          enabled: !_otpSent && !_loadingProfile,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: lang.translate('emergency_contact_phone_field'),
                            hintText: lang.translate('emergency_phone_hint'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Residential Address
                        TextField(
                          controller: _addressController,
                          enabled: !_otpSent && !_loadingProfile,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: lang.translate('residential_address_field'),
                            hintText: lang.translate('address_hint'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // OTP Verification Box
                Card(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.translate('phone_number_label'),
                          style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
                        ),
                        const SizedBox(height: 12),

                        if (!_otpSent) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : () => _sendOtp(phone, lang),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navy),
                              child: _submitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(lang.translate('request_otp_btn')),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: lang.translate('otp_code_label'),
                              hintText: '123456',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _submitting ? null : () => _sendOtp(phone, lang),
                                  child: Text(lang.locale == 'en' ? 'Resend Code' : 'Tuma Tena Namba'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : () => _submitApplication(phone, lang),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: _submitting
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(lang.translate('submit_loan_btn')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const DriverSubPageNavBar(type: 'loans', activeIndex: 1),
    );
  }

  String _formatCurrency(double value) {
    String str = value.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.gray,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppTheme.navy,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
