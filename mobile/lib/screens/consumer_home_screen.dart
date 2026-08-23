import 'package:flutter/material.dart';
import '../models/service_request.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'consumer_request_detail_screen.dart';
import 'role_select_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  int _currentNavIndex = 0;
  List<ServiceRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final consumer = SessionManager().currentConsumer;
    if (consumer == null) return;

    setState(() => _isLoading = true);

    try {
      final reqs = await ApiService().getConsumerRequests(consumer.id);
      if (mounted) {
        setState(() => _requests = reqs);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewRequestDialog() async {
    final consumer = SessionManager().currentConsumer;
    if (consumer == null) return;

    final skills = await ApiService().getSkills();
    final locations = await ApiService().getLocations();

    String selectedSkill = skills.first;
    String selectedLocation = locations.first;
    final descController = TextEditingController();
    bool isSubmitting = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Request a Local Pro',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'We will automatically notify and match the best available pros in your area.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  // Skill Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedSkill,
                    decoration: const InputDecoration(
                      labelText: 'Service Needed',
                      prefixIcon: Icon(Icons.construction_rounded),
                    ),
                    items: skills
                        .map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSkill = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Location Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Your Locality',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: locations
                        .map((l) => DropdownMenuItem(value: l, child: Text(l[0].toUpperCase() + l.substring(1))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedLocation = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Issue Details (Optional)',
                      hintText: 'e.g. Kitchen tap leaking or fan switch repair',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              await ApiService().createServiceRequest(
                                consumerPhone: consumer.phone,
                                skill: selectedSkill,
                                location: selectedLocation,
                                description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                              );
                              if (bottomSheetContext.mounted) Navigator.pop(bottomSheetContext);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Request created! Matching nearby pros.'),
                                    backgroundColor: AppTheme.consumerPrimary,
                                  ),
                                );
                                _loadRequests();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.consumerPrimary),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Find Providers Now ⚡'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRatingModal(ServiceRequest req) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'Rate & Complete Job',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How was ${req.provider?.name ?? "the pro"}\'s work for Job #${req.id}?',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 38,
                          color: AppTheme.warning,
                        ),
                        onPressed: () => setModalState(() => rating = star),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Optional Comment Field
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Feedback / Comment (Optional)',
                      hintText: 'e.g. Arrived on time, fixed quickly!',
                    ),
                  ),
                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              await ApiService().completeRequest(
                                req.id,
                                rating,
                                commentController.text.trim().isNotEmpty ? commentController.text.trim() : null,
                              );
                              if (modalCtx.mounted) Navigator.pop(modalCtx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 Thank you! Rating and job completion recorded.'),
                                    backgroundColor: AppTheme.consumerPrimary,
                                  ),
                                );
                                _loadRequests();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Completion failed: $e'), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.consumerPrimary),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Mark Done & Submit Rating'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCancelRequest(ServiceRequest req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel Request?'),
        content: Text(
          'Are you sure you want to cancel Request #${req.id} for ${req.skillRequested.toUpperCase()}?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Request', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().cancelRequest(req.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Request #${req.id} has been cancelled.'),
                      backgroundColor: AppTheme.ctaDark,
                    ),
                  );
                  _loadRequests();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    SessionManager().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final consumer = SessionManager().currentConsumer;

    if (_currentNavIndex == 1) {
      return _buildConsumerProfileView(consumer);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(consumer?.name ?? 'Customer Portal', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(
              '+91 ${consumer?.phone ?? ""}',
              style: const TextStyle(fontSize: 11, color: AppTheme.consumerPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadRequests,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewRequestDialog,
        backgroundColor: AppTheme.consumerPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('New Request', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        color: AppTheme.consumerPrimary,
        child: Column(
          children: [
            // Consumer Greeting Hero Card
            _buildConsumerHero(consumer),

            // Requests List
            Expanded(child: _buildRequestsList()),
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
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.consumerPrimary,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'My Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerHero(dynamic consumer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.consumerHeroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.consumerHeroShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${consumer?.name ?? "Welcome"}! 👋',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Need home repairs or services? Tap "New Request" anytime.',
                  style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.consumerPrimary));
    }

    if (_requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.search_rounded, size: 60, color: AppTheme.textMuted),
          SizedBox(height: 14),
          Text(
            'No Service Requests Yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap "New Request" below to quickly find electricians, plumbers, carpenters and other pros near you.',
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
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final req = _requests[i];
        final isMatched = req.isMatched;
        final isCompleted = req.isCompleted;
        final isCancelled = req.status.toLowerCase() == 'cancelled';

        Color badgeColor = AppTheme.warning;
        String badgeText = 'SEARCHING';
        if (isMatched) {
          badgeColor = AppTheme.consumerPrimary;
          badgeText = 'MATCHED';
        } else if (isCompleted) {
          badgeColor = AppTheme.success;
          badgeText = 'COMPLETED';
        } else if (isCancelled) {
          badgeColor = AppTheme.textMuted;
          badgeText = 'CANCELLED';
        }

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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${req.id} • ${req.skillRequested.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.consumerPrimary),
                  const SizedBox(width: 4),
                  Text(req.location.toUpperCase(), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (req.isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PAID ✓', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              if (req.provider != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.consumerSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.consumerPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        req.provider!.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                      ),
                      const Spacer(),
                      Text(
                        '★ ${req.provider!.ratingAvg}',
                        style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              if (isCompleted && req.rating != null) ...[
                const SizedBox(height: 8),
                Text('Rated: ${"★" * req.rating!} (${req.rating}/5)', style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 14),

              // Actions Row (View Pro / Pay, Done & Rate, Cancel)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsumerRequestDetailScreen(request: req),
                          ),
                        );
                        _loadRequests();
                      },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                      child: const Text('Details / QR'),
                    ),
                  ),
                  if (isMatched) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showRatingModal(req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.consumerPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Done & Rate', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                  if (!isCompleted && !isCancelled) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.error, size: 20),
                      tooltip: 'Cancel Request',
                      onPressed: () => _confirmCancelRequest(req),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsumerProfileView(dynamic consumer) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Customer Profile'),
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.consumerHeroGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        consumer?.name?.isNotEmpty == true ? consumer.name[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consumer?.name ?? 'Customer',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+91 ${consumer?.phone ?? ""}',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
              label: const Text('Logout from Account', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
