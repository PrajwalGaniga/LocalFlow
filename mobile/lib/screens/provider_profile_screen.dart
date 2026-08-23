import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../models/service_location.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/location_picker_dialog.dart';
import 'provider_register_screen.dart';
import 'role_select_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  @override
  void initState() {
    super.initState();
    _refreshProfiles();
  }

  Future<void> _refreshProfiles() async {
    final provider = SessionManager().currentProvider;
    if (provider == null) return;

    try {
      final profiles = await ApiService().getAllProvidersByPhone(provider.phone);
      if (mounted && profiles.isNotEmpty) {
        SessionManager().setAvailableProviderProfiles(profiles);
      }
    } catch (_) {}
  }

  void _showEditProfileDialog() async {
    final provider = SessionManager().currentProvider;
    if (provider == null) return;

    final nameController = TextEditingController(text: provider.name);
    final minRateController = TextEditingController(text: provider.rateMin?.toString() ?? '300');
    final maxRateController = TextEditingController(text: provider.rateMax?.toString() ?? '600');

    final skills = await ApiService().getSkills();
    String selectedSkill = skills.contains(provider.skill) ? provider.skill : skills.first;
    ServiceLocation? selectedLocation = provider.location;
    String selectedStatus = provider.availabilityStatus;
    bool isSaving = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            void chooseLocation() async {
              final loc = await LocationPickerDialog.show(
                dialogCtx,
                initialLocation: selectedLocation,
                primaryColor: AppTheme.providerPrimary,
              );
              if (loc != null) {
                setModalState(() => selectedLocation = loc);
              }
            }

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
                    'Edit Provider Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 18),

                  // Name Field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Skill Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedSkill,
                    decoration: const InputDecoration(
                      labelText: 'Primary Service Skill',
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

                  // Location Selector
                  GestureDetector(
                    onTap: chooseLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppTheme.providerPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Service Locality',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedLocation?.formattedArea ?? provider.locationFull,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rate Min / Max
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minRateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Rate (₹)',
                            prefixIcon: Icon(Icons.currency_rupee_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxRateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Rate (₹)',
                            prefixIcon: Icon(Icons.currency_rupee_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Availability Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Current Availability',
                      prefixIcon: Icon(Icons.access_time_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'available_now', child: Text('🟢 Available Now')),
                      DropdownMenuItem(value: 'available_later', child: Text('🟡 Available Later')),
                      DropdownMenuItem(value: 'busy', child: Text('🔴 Busy on a Job')),
                      DropdownMenuItem(value: 'offline', child: Text('⚪ Offline')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              final updated = await ApiService().updateProviderProfile(
                                provider.id,
                                name: nameController.text.trim(),
                                skill: selectedSkill,
                                locationId: selectedLocation?.id,
                                rateMin: int.tryParse(minRateController.text.trim()),
                                rateMax: int.tryParse(maxRateController.text.trim()),
                                availabilityStatus: selectedStatus,
                              );
                              SessionManager().loginAsProvider(updated, SessionManager().availableProviderProfiles);
                              _refreshProfiles();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Profile updated successfully!'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                                setState(() {});
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary),
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    final provider = SessionManager().currentProvider;
    final allProfiles = SessionManager().availableProviderProfiles;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card Header
            if (provider != null) _buildProfileHeader(provider),
            const SizedBox(height: 20),

            // Multi-Skill Profile Switcher
            _buildMultiProfileSwitcher(allProfiles, provider),
            const SizedBox(height: 20),

            // Profile Details Card
            if (provider != null) _buildDetailsCard(provider),
            const SizedBox(height: 28),

            // Logout Button
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
              label: const Text('Logout from Account', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Provider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.providerHeroGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Center(
              child: Text(
                provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        provider.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: AppTheme.providerPrimary, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '+91 ${provider.phone}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.providerPeach,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '★ ${provider.ratingAvg} (${provider.ratingCount} Reviews)',
                    style: const TextStyle(
                      color: AppTheme.providerDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiProfileSwitcher(List<Provider> profiles, Provider? activeProvider) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Registered Skills',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProviderRegisterScreen(),
                    ),
                  ).then((_) => _refreshProfiles());
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 16, color: AppTheme.providerPrimary),
                      SizedBox(width: 4),
                      Text(
                        'Add Skill',
                        style: TextStyle(color: AppTheme.providerPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You can register multiple skills (e.g. Electrician & Plumber) and switch active jobs anytime.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),

          // Profile Pills / Cards
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profiles.map((p) {
              final isSelected = p.id == activeProvider?.id;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  SessionManager().switchProviderProfile(p);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${p.skill.toUpperCase()} (${p.locationName.toUpperCase()})'),
                      backgroundColor: AppTheme.providerPrimary,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.providerPrimary : AppTheme.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.providerPrimary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${p.skill.toUpperCase()} (${p.locationName.toUpperCase()})',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Provider provider) {
    return Container(
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
            'Service Details',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.construction_rounded, 'Primary Skill', provider.skill.toUpperCase()),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(Icons.location_on_outlined, 'Primary Locality', provider.locationFull.toUpperCase()),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(Icons.currency_rupee_rounded, 'Standard Rates', '₹${provider.rateMin ?? 300} – ₹${provider.rateMax ?? 600} / visit'),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(Icons.bolt_rounded, 'Availability', provider.availabilityStatus.replaceAll('_', ' ').toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.providerPrimary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}
