import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'consumer_home_screen.dart';

class ConsumerRegisterScreen extends StatefulWidget {
  final String initialPhone;

  const ConsumerRegisterScreen({super.key, required this.initialPhone});

  @override
  State<ConsumerRegisterScreen> createState() => _ConsumerRegisterScreenState();
}

class _ConsumerRegisterScreenState extends State<ConsumerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consumer = await ApiService().registerConsumer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null,
      );

      SessionManager().loginAsConsumer(consumer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome to LocalFlow! Start finding local pros.'),
            backgroundColor: AppTheme.consumerPrimary,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ConsumerHomeScreen()),
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Customer Registration'),
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
                      color: AppTheme.consumerSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppTheme.consumerPrimary, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Customer Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connect with verified plumbers, electricians, carpenters and tutors near you in seconds.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Priya Sharma',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: (val) {
                    final clean = (val ?? '').replaceAll(RegExp(r'\D'), '');
                    if (clean.length < 10) return 'Valid 10-digit phone required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (Optional)',
                    hintText: 'e.g. 12345678',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.consumerPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Create Account →',
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
