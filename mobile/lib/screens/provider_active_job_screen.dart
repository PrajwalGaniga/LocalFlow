import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProviderActiveJobScreen extends StatefulWidget {
  final int requestId;
  final String consumerPhone;
  final String? consumerName;
  final String location;
  final String? description;
  final int? rateMin;
  final int? rateMax;

  const ProviderActiveJobScreen({
    super.key,
    required this.requestId,
    required this.consumerPhone,
    this.consumerName,
    required this.location,
    this.description,
    this.rateMin,
    this.rateMax,
  });

  @override
  State<ProviderActiveJobScreen> createState() => _ProviderActiveJobScreenState();
}

class _ProviderActiveJobScreenState extends State<ProviderActiveJobScreen> {
  bool _isPaid = false;

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
              '₹$amount has been marked as collected for Job #${widget.requestId}.',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ctaDark),
              child: const Text('Awesome'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentQrDialog() {
    final amountController = TextEditingController(
      text: widget.rateMin != null ? '${widget.rateMin}' : '350',
    );
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            final amount = amountController.text.trim().isEmpty ? '350' : amountController.text.trim();
            final upiString =
                'upi://pay?pa=localflow.provider@upi&pn=LocalFlow&am=$amount&tn=LocalFlow_Job_${widget.requestId}';

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'UPI Payment QR Code',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Customer can scan with Google Pay, PhonePe, or Paytm',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  // QR Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: QrImageView(
                      data: upiString,
                      version: QrVersions.auto,
                      size: 190.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Amount Edit Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Amount: ₹',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.providerPrimary,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (val) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Done & Canceled Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(bottomCtx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Canceled'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setModalState(() => isProcessing = true);
                                  try {
                                    await ApiService().markRequestPaid(widget.requestId);
                                    if (mounted) setState(() => _isPaid = true);
                                    if (bottomCtx.mounted) Navigator.pop(bottomCtx);
                                    if (mounted) _showPaymentSuccessDialog(amount);
                                  } catch (e) {
                                    setModalState(() => isProcessing = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Payment update failed: $e'), backgroundColor: AppTheme.error),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isProcessing
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Done ✓', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rateText = (widget.rateMin != null && widget.rateMax != null)
        ? '₹${widget.rateMin} – ₹${widget.rateMax}'
        : 'Standard Rates';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Active Job #${widget.requestId}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Status Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.providerHeroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.heroShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Confirmed — You Won!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Contact customer directly to coordinate arrival and work.',
                            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Customer Details Card
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
                      'CUSTOMER CONTACT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.providerPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.providerPeach,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person_rounded, color: AppTheme.providerPrimary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.consumerName ?? 'Customer',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+91 ${widget.consumerPhone}',
                                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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

              // Job Details Card
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
                      'JOB SPECIFICATIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.providerPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(Icons.location_on_outlined, 'Location', widget.location.toUpperCase()),
                    const Divider(height: 22, thickness: 0.5),
                    _buildDetailRow(Icons.payments_outlined, 'Estimated Rate', rateText),
                    const Divider(height: 22, thickness: 0.5),
                    _buildDetailRow(
                      Icons.description_outlined,
                      'Issue Details',
                      widget.description ?? 'General service requested',
                    ),
                    if (_isPaid) ...[
                      const Divider(height: 22, thickness: 0.5),
                      _buildDetailRow(Icons.check_circle_rounded, 'Payment Status', 'PAID ✓ (₹ Collected)'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Action Button
              ElevatedButton.icon(
                onPressed: _showPaymentQrDialog,
                icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                label: Text(_isPaid ? 'Show Payment QR Again' : 'Show Payment QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ctaDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
