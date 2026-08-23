import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'provider_register_screen.dart';
import 'consumer_register_screen.dart';
import 'provider_home_screen.dart';
import 'consumer_home_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  final UserRole role;

  const PhoneLoginScreen({super.key, required this.role});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isProvider => widget.role == UserRole.provider;

  Future<void> _handleContinue() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final password = _passwordController.text.trim();

    if (phone.length < 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isProvider) {
        // 1. Check if provider exists
        final allProfiles = await ApiService().getAllProvidersByPhone(phone);
        if (allProfiles.isNotEmpty) {
          final primary = allProfiles.first;
          if (password.isNotEmpty) {
            final loggedIn = await ApiService().loginProvider(phone, password);
            SessionManager().loginAsProvider(loggedIn, allProfiles);
          } else {
            SessionManager().loginAsProvider(primary, allProfiles);
          }
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ProviderHomeScreen()),
              (route) => false,
            );
          }
        } else {
          // Not found -> Route to Provider Registration
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderRegisterScreen(initialPhone: phone),
              ),
            );
          }
        }
      } else {
        // Consumer flow
        final consumer = await ApiService().getConsumerByPhone(phone);
        if (consumer != null) {
          if (password.isNotEmpty) {
            final loggedIn = await ApiService().loginConsumer(phone, password);
            SessionManager().loginAsConsumer(loggedIn);
          } else {
            SessionManager().loginAsConsumer(consumer);
          }
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ConsumerHomeScreen()),
              (route) => false,
            );
          }
        } else {
          // Not found -> Route to Consumer Registration
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConsumerRegisterScreen(initialPhone: phone),
              ),
            );
          }
        }
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

  void _showServerConfig(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Backend Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FastAPI Server URL (e.g. ngrok or custom domain):',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://xxxx.ngrok-free.dev',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ApiConfig.reset();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reset to default: ${ApiConfig.baseUrl}')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ApiConfig.baseUrl = controller.text.trim();
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connected to: ${ApiConfig.baseUrl}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleName = isProvider ? 'Service Provider' : 'Customer';
    final activeColor = isProvider ? AppTheme.providerPrimary : AppTheme.consumerPrimary;
    final activeBg = isProvider ? AppTheme.providerPeach : AppTheme.consumerSoft;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('$roleName Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: AppTheme.textSecondary),
            tooltip: 'Server Settings',
            onPressed: () => _showServerConfig(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: activeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isProvider ? Icons.handyman_rounded : Icons.person_rounded,
                    color: activeColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter Mobile Number',
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
                'Enter your 10-digit phone number. Registered users log in instantly, and new users will be guided to signup.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Phone Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                  prefixText: '+91 ',
                  hintText: '98765 43210',
                ),
              ),
              const SizedBox(height: 14),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (Optional)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  hintText: 'Enter your password if set',
                ),
              ),
              const SizedBox(height: 18),

              // Error Message
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

              // Continue CTA Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Continue →',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
