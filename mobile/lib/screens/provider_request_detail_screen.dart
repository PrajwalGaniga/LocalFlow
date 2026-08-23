import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'provider_active_job_screen.dart';

class ProviderRequestDetailScreen extends StatefulWidget {
  final int providerId;
  final NotificationItem notification;
  final int? rateMin;
  final int? rateMax;

  const ProviderRequestDetailScreen({
    super.key,
    required this.providerId,
    required this.notification,
    this.rateMin,
    this.rateMax,
  });

  @override
  State<ProviderRequestDetailScreen> createState() => _ProviderRequestDetailScreenState();
}

class _ProviderRequestDetailScreenState extends State<ProviderRequestDetailScreen> {
  final ApiService _api = ApiService();
  bool _isSubmitting = false;

  Future<void> _handleAccept() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await _api.acceptNotification(
        widget.providerId,
        widget.notification.requestId,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // Navigate to active job screen with revealed customer contact
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderActiveJobScreen(
              requestId: widget.notification.requestId,
              consumerPhone: res['consumer_phone'] ?? '',
              consumerName: res['consumer_name'],
              location: res['location'] ?? widget.notification.request?.locationFull ?? 'Local Area',
              description: res['description'] ?? widget.notification.request?.description,
              rateMin: res['rate_min'] ?? widget.rateMin,
              rateMax: res['rate_max'] ?? widget.rateMax,
            ),
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        _showErrorDialog(res['message'] ?? 'Job already taken by another provider.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  Future<void> _handleDecline() async {
    setState(() => _isSubmitting = true);
    try {
      await _api.declineNotification(widget.providerId, widget.notification.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead declined.'),
            backgroundColor: AppTheme.surfaceMuted,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.providerPrimary),
            SizedBox(width: 10),
            Text('Job Unavailable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Back to Leads'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.notification.request;
    final skillName = req?.skillRequested.toUpperCase() ?? 'SERVICE';
    final locationText = req?.locationFull ?? 'Karnataka Locality';
    final descText = req?.description?.trim().isNotEmpty == true
        ? req!.description!
        : 'General service assistance requested.';
    final rateText = (widget.rateMin != null && widget.rateMax != null)
        ? '₹${widget.rateMin} – ₹${widget.rateMax}'
        : 'Standard Rates (₹350 – ₹600)';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Lead #${widget.notification.requestId}'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Skill and Location Hero Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.providerHeroGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.heroShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  skillName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.flash_on, color: Colors.amberAccent, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'New Lead',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Estimated Rate: $rateText',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Job Specifications Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.04)),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JOB DESCRIPTION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.providerPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            descText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Divider(height: 28, thickness: 0.5),
                          _buildDetailRow(
                            Icons.tune_outlined,
                            'Service Type',
                            req?.skillRequested.toUpperCase() ?? 'Standard',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.map_outlined,
                            'General Area',
                            req?.location?.district ?? 'Karnataka',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.currency_rupee,
                            'Rate Range',
                            rateText,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Privacy Shield Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: AppTheme.providerPrimary, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer Privacy Protected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'The customer\'s name, exact address, and contact number will be unlocked immediately once you accept this request.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Action Bar (Accept & Decline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _handleDecline,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text('Decline', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.providerPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Accept Job',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.providerPrimary),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
