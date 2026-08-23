import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/provider_wallet.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  ProviderWallet? _wallet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final provider = SessionManager().currentProvider;
    if (provider == null) return;

    setState(() => _isLoading = true);
    try {
      final w = await ApiService().getProviderWallet(provider.id);
      if (mounted) setState(() => _wallet = w);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWithdrawStub() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppTheme.providerPrimary),
            SizedBox(width: 10),
            Text('Withdraw Earnings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available to withdraw: ₹${_wallet?.availableBalance ?? 0}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Funds will be transferred directly to your linked UPI VPA / Bank Account within 2 hours.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Withdrawal request submitted! Payout processed via UPI.'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary),
            child: const Text('Confirm Payout'),
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
        title: const Text('My Wallet & Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadWallet,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        color: AppTheme.providerPrimary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.providerPrimary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Balance Card
                    _buildBalanceHero(),
                    const SizedBox(height: 20),

                    // Quick Stats Row
                    _buildStatsRow(),
                    const SizedBox(height: 28),

                    // Transactions Ledger
                    const Text(
                      'Earnings History',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionsList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceHero() {
    final balance = _wallet?.availableBalance ?? 0;
    final total = _wallet?.totalEarnings ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.providerHeroGradient,
        borderRadius: BorderRadius.circular(28),
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
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Verified Payouts',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '₹$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Lifetime Payout', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('₹$total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showWithdrawStub,
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                label: const Text('Withdraw', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ctaDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final jobs = _wallet?.jobsCompleted ?? 0;
    final rating = _wallet?.ratingAvg ?? 5.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.success,
            label: 'Jobs Completed',
            value: '$jobs Jobs',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.star_rounded,
            color: AppTheme.warning,
            label: 'Customer Rating',
            value: '★ ${rating.toStringAsFixed(1)}',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final transactions = _wallet?.transactions ?? [];

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'No Earnings Yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'Completed jobs and collected UPI payments will appear here with payout status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (ctx, i) {
        final tx = transactions[i];
        final dateStr = tx.completedAt != null
            ? DateFormat('dd MMM, hh:mm a').format(tx.completedAt!)
            : 'Recent';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.success, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${tx.requestId} • ${tx.skill.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tx.location.toUpperCase()} • $dateStr',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+ ₹${tx.amount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.status.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
