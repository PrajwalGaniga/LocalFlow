import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'provider_home_screen.dart';

class ProviderRegisterScreen extends StatefulWidget {
  final String? initialPhone;

  const ProviderRegisterScreen({super.key, this.initialPhone});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TextEditingController _phoneController;
  final _rateMinController = TextEditingController(text: '300');
  final _rateMaxController = TextEditingController(text: '700');
  final _passwordController = TextEditingController();

  List<String> _skills = ['electrician', 'plumber', 'carpenter', 'painter', 'tailor', 'tutor'];
  List<String> _locations = ['koramangala', 'indiranagar', 'hsr layout', 'whitefield', 'jayanagar', 'marathahalli'];

  String? _selectedSkill;
  String? _selectedLocation;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final defaultPhone = widget.initialPhone ?? SessionManager().currentProvider?.phone ?? '';
    _phoneController = TextEditingController(text: defaultPhone);
    if (SessionManager().currentProvider != null) {
      _nameController.text = SessionManager().currentProvider!.name;
    }
    _selectedSkill = _skills.first;
    _selectedLocation = _locations.first;
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final skills = await ApiService().getSkills();
      final locations = await ApiService().getLocations();
      if (mounted) {
        setState(() {
          _skills = skills;
          _locations = locations;
          if (!_skills.contains(_selectedSkill)) _selectedSkill = _skills.first;
          if (!_locations.contains(_selectedLocation)) _selectedLocation = _locations.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rateMin = int.tryParse(_rateMinController.text.trim());
      final rateMax = int.tryParse(_rateMaxController.text.trim());

      final provider = await ApiService().registerProvider(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        skill: _selectedSkill!,
        location: _selectedLocation!,
        rateMin: rateMin,
        rateMax: rateMax,
        password: _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null,
      );

      final allProfiles = await ApiService().getAllProvidersByPhone(provider.phone);
      SessionManager().loginAsProvider(provider, allProfiles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Registration successful! Welcome to LocalFlow.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProviderHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAddingSkill = SessionManager().currentProvider != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isAddingSkill ? 'Add New Skill Profile' : 'Provider Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.providerPeach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handyman_rounded, color: AppTheme.providerPrimary, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAddingSkill ? 'Register Another Skill' : 'Create Provider Profile',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join the verified network to get notified of jobs in your locality.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    hintText: 'e.g. Ramesh Kumar',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                    prefixText: '+91 ',
                  ),
                  validator: (val) {
                    final clean = (val ?? '').replaceAll(RegExp(r'\D'), '');
                    if (clean.length < 10) return 'Enter a valid 10-digit phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Skill Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedSkill,
                  decoration: const InputDecoration(
                    labelText: 'Primary Service / Skill *',
                    prefixIcon: Icon(Icons.construction_rounded),
                  ),
                  items: _skills
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s[0].toUpperCase() + s.substring(1)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSkill = val);
                  },
                ),
                const SizedBox(height: 14),

                // Location Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Primary Locality *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: _locations
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l[0].toUpperCase() + l.substring(1)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLocation = val);
                  },
                ),
                const SizedBox(height: 14),

                // Rates Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rateMinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Rate (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rateMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Rate (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Account Password (Optional)',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                    hintText: 'e.g. 12345678',
                  ),
                ),
                const SizedBox(height: 18),

                // Error Banner
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.providerPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Complete Registration ⚡',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
