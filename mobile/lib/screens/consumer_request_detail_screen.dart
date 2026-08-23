import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/service_request.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ConsumerRequestDetailScreen extends StatefulWidget {
  final ServiceRequest request;

  const ConsumerRequestDetailScreen({super.key, required this.request});

  @override
  State<ConsumerRequestDetailScreen> createState() => _ConsumerRequestDetailScreenState();
}

class _ConsumerRequestDetailScreenState extends State<ConsumerRequestDetailScreen> {
  late ServiceRequest _req;
  bool _isMarkingPaid = false;
  bool _isCompleting = false;
  int _selectedRating = 5;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _req = widget.request;
    if (_req.rating != null) {
      _selectedRating = _req.rating!;
    }
  }

  void _showPaymentSuccessDialog(String amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Payment of ₹$amount has been marked as settled for Job #${_req.id}.',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.consumerPrimary),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMarkPaid(String amount) async {
    setState(() => _isMarkingPaid = true);
    try {
      final updated = await ApiService().markRequestPaid(_req.id);
      setState(() => _req = updated);
      if (mounted) {
        _showPaymentSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingPaid = false);
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isCompleting = true);
    try {
      final updated = await ApiService().completeRequest(
        _req.id,
        _selectedRating,
        _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
      );
      setState(() => _req = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Thank you for your review! Job completed.'),
            backgroundColor: AppTheme.consumerPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Completion error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel Request?'),
        content: const Text(
          'Are you sure you want to cancel this service request?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().cancelRequest(_req.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request #${_req.id} cancelled.'), backgroundColor: AppTheme.ctaDark),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cancel failed: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _req.isPending;
    final isMatched = _req.isMatched;
    final isCompleted = _req.isCompleted;
    final isCancelled = _req.status.toLowerCase() == 'cancelled';
    final provider = _req.provider;

    final upiAmount = (provider?.rateMin != null) ? '${provider!.rateMin}' : '350';
    final upiString =
        'upi://pay?pa=localflow.provider@upi&pn=LocalFlow&am=$upiAmount&tn=LocalFlow_Job_${_req.id}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Request #${_req.id}'),
        actions: [
          if (!isCompleted && !isCancelled)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
              tooltip: 'Cancel Request',
              onPressed: _handleCancel,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Request Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _req.skillRequested.toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.success.withValues(alpha: 0.12)
                                : isMatched
                                    ? AppTheme.consumerPrimary.withValues(alpha: 0.12)
                                    : isCancelled
                                        ? AppTheme.textMuted.withValues(alpha: 0.12)
                                        : AppTheme.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _req.status.toUpperCase(),
                            style: TextStyle(
                              color: isCompleted
                                  ? AppTheme.success
                                  : isMatched
                                      ? AppTheme.consumerPrimary
                                      : isCancelled
                                          ? AppTheme.textMuted
                                          : AppTheme.warning,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.consumerPrimary),
                        const SizedBox(width: 6),
                        Text(_req.location.toUpperCase(), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (_req.description != null && _req.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(_req.description!, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Searching Banner
              if (isPending) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.warning),
                      SizedBox(height: 16),
                      Text(
                        'Reaching out to nearby pros...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'We have notified verified service providers in your area. As soon as one accepts, their contact and rates will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],

              // Assigned Provider Card
              if (provider != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ASSIGNED SERVICE PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.consumerPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppTheme.consumerHeroGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+91 ${provider.phone}',
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '★ ${provider.ratingAvg}',
                                      style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w800, fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${provider.jobsCompleted} jobs completed',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Payment Section (QR Code + Done / Canceled Buttons)
              if (isMatched || isCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'UPI PAYMENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.consumerPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _req.isPaid
                                  ? AppTheme.success.withValues(alpha: 0.12)
                                  : AppTheme.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _req.isPaid ? 'PAID ✓' : 'UNPAID',
                              style: TextStyle(
                                color: _req.isPaid ? AppTheme.success : AppTheme.warning,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_req.isPaid) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: QrImageView(
                            data: upiString,
                            version: QrVersions.auto,
                            size: 160.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan with GPay / PhonePe / Paytm (₹$upiAmount)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Payment cancelled / dismissed.')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Canceled'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _isMarkingPaid ? null : () => _handleMarkPaid(upiAmount),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: _isMarkingPaid
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Done ✓', style: TextStyle(fontWeight: FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Payment settled directly via UPI',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Job Completion & Rating Section
              if (isMatched) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'RATE & COMPLETE JOB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.consumerPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Has the pro finished the job? Leave a rating to complete:',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return IconButton(
                            icon: Icon(
                              starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: AppTheme.warning,
                              size: 36,
                            ),
                            onPressed: () => setState(() => _selectedRating = starIndex),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Review / Comment (Optional)',
                          hintText: 'e.g. Arrived quickly and fixed the issue perfectly',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isCompleting ? null : _handleComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.consumerPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isCompleting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Complete & Submit Rating ★', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],

              if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppTheme.success, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Job Completed & Closed',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            if (_req.rating != null)
                              Text(
                                'You rated: ${"★" * _req.rating!} (${_req.rating}/5)',
                                style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            if (_req.ratingComment != null)
                              Text(
                                '"${_req.ratingComment}"',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
