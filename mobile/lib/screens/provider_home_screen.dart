import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';
import '../models/service_request.dart';
import '../models/provider.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'provider_active_job_screen.dart';
import 'provider_request_detail_screen.dart';
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

  void _openRequestDetail(NotificationItem item) async {
    final provider = SessionManager().currentProvider;
    if (provider == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderRequestDetailScreen(
          providerId: provider.id,
          notification: item,
          rateMin: provider.rateMin,
          rateMax: provider.rateMax,
        ),
      ),
    );

    if (result == true || mounted) {
      _loadData();
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
              '${provider?.skill.toUpperCase()} • ${provider?.locationName.toUpperCase()}',
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
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0 || index == 1) _loadData();
        },
        selectedItemColor: AppTheme.providerPrimary,
        unselectedItemColor: AppTheme.textMuted,
        backgroundColor: AppTheme.surface,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _notifications.isNotEmpty,
              label: Text('${_notifications.length}'),
              backgroundColor: AppTheme.providerPrimary,
              child: const Icon(Icons.bolt_rounded),
            ),
            label: 'Leads',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
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

  Widget _buildProviderHero(Provider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.ratingAvg}★ (${provider.ratingCount})',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${provider.jobsCompleted} jobs',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(
                      provider.availabilityStatus.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.providerDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroStat('RATE RANGE', '₹${provider.rateMin ?? 250} - ₹${provider.rateMax ?? 500}'),
                Container(width: 1, height: 24, color: Colors.white24),
                _buildHeroStat('LOCATION', provider.locationName.toUpperCase()),
                Container(width: 1, height: 24, color: Colors.white24),
                _buildHeroStat('STATUS', 'ACTIVE'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
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
              'Pull down to refresh. Whenever a customer in your locality requests your skill, it will appear here instantly.',
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
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: InkWell(
            onTap: () => _openRequestDetail(item),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                      Expanded(
                        child: Text(
                          req?.locationFull.toUpperCase() ?? 'LOCALITY',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  if (req?.description != null && req!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      req.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.providerPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.providerPrimary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Details & Decide',
                          style: TextStyle(
                            color: AppTheme.providerPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: AppTheme.providerPrimary, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isCompleted
                  ? AppTheme.success.withOpacity(0.12)
                  : AppTheme.providerPeach,
              child: Icon(
                isCompleted ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                color: isCompleted ? AppTheme.success : AppTheme.providerPrimary,
              ),
            ),
            title: Text(
              '#${job.id} • ${job.skillRequested.toUpperCase()} (${job.locationName.toUpperCase()})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  job.consumerName != null
                      ? 'Customer: ${job.consumerName} (+91 ${job.consumerPhone})'
                      : 'Customer: +91 ${job.consumerPhone}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
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
                    consumerName: job.consumerName,
                    location: job.locationFull,
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
