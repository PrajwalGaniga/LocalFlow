import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'phone_login_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

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
              'Set the FastAPI backend URL (e.g. ngrok or custom domain):',
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.providerPeach,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: AppTheme.providerDark, size: 16),
              SizedBox(width: 4),
              Text(
                'LOCALFLOW',
                style: TextStyle(
                  color: AppTheme.providerDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/app-logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Container(
                        decoration: BoxDecoration(
                          color: AppTheme.providerPeach,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: AppTheme.providerPrimary, size: 50),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Instant Local Services',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Match instantly with verified local service professionals or manage your customer leads.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Role 1: Provider (Warm Coral Gradient Card)
              _buildRoleCard(
                context,
                title: "I'm a Service Provider",
                subtitle: 'Receive instant jobs in your locality, track wallet earnings, and collect direct UPI payments.',
                icon: Icons.handyman_rounded,
                accentColor: AppTheme.providerPrimary,
                badgeBg: AppTheme.providerPeach,
                role: UserRole.provider,
              ),
              const SizedBox(height: 14),

              // Role 2: Consumer (Fresh Emerald Green Card)
              _buildRoleCard(
                context,
                title: "I'm a Customer",
                subtitle: 'Request electricians, plumbers, painters, and more in seconds with live status tracking.',
                icon: Icons.person_search_rounded,
                accentColor: AppTheme.consumerPrimary,
                badgeBg: AppTheme.consumerSoft,
                role: UserRole.consumer,
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Connected Server: ${ApiConfig.baseUrl}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color badgeBg,
    required UserRole role,
  }) {
    return InkWell(
      onTap: () {
        SessionManager().selectRole(role);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhoneLoginScreen(role: role),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
