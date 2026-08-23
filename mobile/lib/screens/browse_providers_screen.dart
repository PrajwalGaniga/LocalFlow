import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../models/service_location.dart';
import '../models/service_request.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/location_picker_dialog.dart';
import 'consumer_request_detail_screen.dart';

class BrowseProvidersScreen extends StatefulWidget {
  final String? initialSkill;
  final ServiceLocation? initialLocation;

  const BrowseProvidersScreen({
    super.key,
    this.initialSkill,
    this.initialLocation,
  });

  @override
  State<BrowseProvidersScreen> createState() => _BrowseProvidersScreenState();
}

class _BrowseProvidersScreenState extends State<BrowseProvidersScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Provider> _providers = [];
  List<String> _skills = [];

  String? _selectedSkill;
  ServiceLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedSkill = widget.initialSkill;
    _selectedLocation = widget.initialLocation;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      final skills = await _api.getSkills();
      setState(() {
        _skills = skills;
      });
      await _fetchProviders();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProviders() async {
    setState(() => _isLoading = true);
    try {
      final pros = await _api.browseProviders(
        skill: _selectedSkill,
        locationId: _selectedLocation?.id,
      );
      if (mounted) {
        setState(() {
          _providers = pros;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _chooseLocation() async {
    final loc = await LocationPickerDialog.show(
      context,
      initialLocation: _selectedLocation,
      primaryColor: AppTheme.consumerPrimary,
    );
    if (loc != null) {
      setState(() => _selectedLocation = loc);
      _fetchProviders();
    }
  }

  void _handleDirectRequest(Provider pro) {
    final consumer = SessionManager().currentConsumer;
    if (consumer == null) return;

    final descController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (bottomCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 24,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.consumerMint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_pin_rounded, color: AppTheme.consumerPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request ${pro.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${pro.skill.toUpperCase()} • ${pro.locationFull}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Describe what service you need (optional):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Need help fixing the kitchen switchboard...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppTheme.consumerPrimary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated Rate: ₹${pro.rateMin ?? 250} - ₹${pro.rateMax ?? 500} • Contact details shared upon acceptance.',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            final locId = pro.locationId ?? _selectedLocation?.id ?? 1;
                            final newReq = await _api.createServiceRequest(
                              consumerPhone: consumer.phone,
                              skill: pro.skill,
                              locationId: locId,
                              description: descController.text.trim().isNotEmpty
                                  ? descController.text.trim()
                                  : 'Direct request to ${pro.name}',
                              preferredProviderId: pro.id,
                            );

                            if (bottomCtx.mounted) Navigator.pop(bottomCtx);
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ConsumerRequestDetailScreen(request: newReq),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.consumerPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Send Request to ${pro.name} ⚡',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Browse Nearby Pros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProviders,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Filters Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppTheme.surface,
              child: Column(
                children: [
                  // Location Picker Tile
                  GestureDetector(
                    onTap: _chooseLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.consumerPrimary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.consumerPrimary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LOCATION FILTER',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.consumerPrimary),
                                ),
                                Text(
                                  _selectedLocation?.formattedArea ?? 'All Karnataka Locations (Tap to filter)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.tune_rounded, color: AppTheme.consumerPrimary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Skill Filter Horizontal Chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSkillChip('All Skills', null),
                        ..._skills.map((s) => _buildSkillChip(s.toUpperCase(), s)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Providers List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.consumerPrimary))
                  : _providers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          itemCount: _providers.length,
                          itemBuilder: (ctx, idx) => _buildProviderCard(_providers[idx]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String label, String? skillVal) {
    final isSelected = _selectedSkill == skillVal;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedSkill = skillVal);
          _fetchProviders();
        },
        selectedColor: AppTheme.consumerPrimary,
        backgroundColor: AppTheme.surfaceSoft,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildProviderCard(Provider pro) {
    final rateText = (pro.rateMin != null && pro.rateMax != null)
        ? '₹${pro.rateMin} – ₹${pro.rateMax}'
        : 'Standard Rates';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.consumerMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.engineering_rounded, color: AppTheme.consumerPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pro.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppTheme.consumerPrimary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pro.skill.toUpperCase()} • ${pro.locationName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      '${pro.ratingAvg}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 15, color: AppTheme.consumerPrimary),
                    const SizedBox(width: 6),
                    Text('${pro.jobsCompleted} jobs completed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                Text(
                  rateText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.consumerPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleDirectRequest(pro),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.consumerPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Request This Person', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.search_off_rounded, size: 60, color: AppTheme.textMuted),
        const SizedBox(height: 14),
        const Text(
          'No Available Pros Found',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Try clearing filters or changing your location area to find nearby verified service providers.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}
