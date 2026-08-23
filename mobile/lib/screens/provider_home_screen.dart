import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';
import '../models/service_request.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'provider_active_job_screen.dart';
import 'provider_wallet_screen.dart';
import 'provider_profile_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _currentIndex = 0;
  List<NotificationItem> _notifications = [];
  List<ServiceRequest> _myJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = SessionManager().currentProvider;
    if (provider == null) return;

    setState(() => _isLoading = true);

    try {
      final notifs = await ApiService().getProviderNotifications(provider.id);
      final jobs = await ApiService().getProviderJobs(provider.id);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _myJobs = jobs;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptJob(NotificationItem item) async {
    final provider = SessionManager().currentProvider;
    if (provider == null) return;

    try {
      final res = await ApiService().acceptNotification(provider.id, item.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Job #${item.requestId} accepted! Customer contact unlocked.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadData();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderActiveJobScreen(
              requestId: item.requestId,
              consumerPhone: res['consumer_phone'] ?? item.request?.consumerPhone ?? '',
              consumerName: res['consumer_name'],
              location: res['location'] ?? item.request?.location ?? provider.location,
              description: res['description'] ?? item.request?.description,
              rateMin: res['rate_min'] ?? provider.rateMin,
              rateMax: res['rate_max'] ?? provider.rateMax,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error),
        );
        _loadData();
      }
    }
  }

  Future<void> _declineJob(NotificationItem item) async {
    final provider = SessionManager().currentProvider;
    if (provider == null) return;

    try {
      await ApiService().declineNotification(provider.id, item.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Declined Job #${item.requestId}')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 2) {
      return Scaffold(
        body: const ProviderWalletScreen(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    if (_currentIndex == 3) {
      return Scaffold(
        body: const ProviderProfileScreen(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    final provider = SessionManager().currentProvider;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(provider?.name ?? 'Provider Portal', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(
              '${provider?.skill.toUpperCase()} • ${provider?.location.toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: AppTheme.providerPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.providerPrimary,
        child: Column(
          children: [
            // Top Status Hero Banner
            if (provider != null) _buildProviderHero(provider),

            // Tab Selector (Leads vs My Jobs)
            _buildTabSelector(),

            // List View Content
            Expanded(
              child: _currentIndex == 0 ? _buildIncomingList() : _buildMyJobsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index <= 1) _loadData();
        },
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.providerPrimary,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _notifications.isNotEmpty,
              label: Text('${_notifications.length}'),
              child: const Icon(Icons.flash_on_rounded),
            ),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _myJobs.isNotEmpty,
              backgroundColor: AppTheme.textSecondary,
              label: Text('${_myJobs.length}'),
              child: const Icon(Icons.work_outline_rounded),
            ),
            label: 'My Jobs',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProviderHero(dynamic provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Rating', '★ ${provider.ratingAvg}', AppTheme.warning),
          Container(width: 1, height: 26, color: Colors.black.withValues(alpha: 0.06)),
          _buildStatItem('Completed', '${provider.jobsCompleted} Jobs', AppTheme.providerPrimary),
          Container(width: 1, height: 26, color: Colors.black.withValues(alpha: 0.06)),
          _buildStatItem('Status', 'Available', AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentIndex = 0),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? AppTheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _currentIndex == 0 ? AppTheme.cardShadow : null,
                ),
                child: Center(
                  child: Text(
                    'Incoming Leads (${_notifications.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: _currentIndex == 0 ? AppTheme.providerPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentIndex = 1),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? AppTheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _currentIndex == 1 ? AppTheme.cardShadow : null,
                ),
                child: Center(
                  child: Text(
                    'My Jobs (${_myJobs.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: _currentIndex == 1 ? AppTheme.providerPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.providerPrimary));
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.inbox_outlined, size: 60, color: AppTheme.textMuted),
          SizedBox(height: 14),
          Text(
            'No Incoming Leads Right Now',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Pull down to refresh. Whenever a customer in your area requests your skill, it will appear here instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (ctx, i) {
        final item = _notifications[i];
        final req = item.request;
        final timeStr = DateFormat('hh:mm a').format(item.notifiedAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.providerPeach,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${item.requestId} • ${(req?.skillRequested ?? "Service").toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.providerDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(timeStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.providerPrimary),
                  const SizedBox(width: 6),
                  Text(
                    (req?.location ?? '').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              if (req?.description != null && req!.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  req.description!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineJob(item),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _acceptJob(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ctaDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept Job ⚡'),
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

  Widget _buildMyJobsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.providerPrimary));
    }

    if (_myJobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.assignment_outlined, size: 60, color: AppTheme.textMuted),
          SizedBox(height: 14),
          Text(
            'No Active or Past Jobs',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Jobs you accept will appear here so you can coordinate with customers and collect payments.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _myJobs.length,
      itemBuilder: (ctx, i) {
        final job = _myJobs[i];
        final isCompleted = job.isCompleted;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isCompleted
                  ? AppTheme.success.withValues(alpha: 0.12)
                  : AppTheme.providerPeach,
              child: Icon(
                isCompleted ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                color: isCompleted ? AppTheme.success : AppTheme.providerPrimary,
              ),
            ),
            title: Text(
              '#${job.id} • ${job.skillRequested.toUpperCase()} (${job.location.toUpperCase()})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Customer: +91 ${job.consumerPhone}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  'Status: ${job.status.toUpperCase()} • Payment: ${job.paymentStatus.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: job.isPaid ? AppTheme.success : AppTheme.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderActiveJobScreen(
                    requestId: job.id,
                    consumerPhone: job.consumerPhone,
                    location: job.location,
                    description: job.description,
                    rateMin: SessionManager().currentProvider?.rateMin,
                    rateMax: SessionManager().currentProvider?.rateMax,
                  ),
                ),
              ).then((_) => _loadData());
            },
          ),
        );
      },
    );
  }
}
