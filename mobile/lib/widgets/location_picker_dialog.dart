import 'package:flutter/material.dart';
import '../models/service_location.dart';
import '../services/api_service.dart';

class LocationPickerDialog extends StatefulWidget {
  final ServiceLocation? initialLocation;
  final Color primaryColor;

  const LocationPickerDialog({
    super.key,
    this.initialLocation,
    this.primaryColor = const Color(0xFF6366F1),
  });

  static Future<ServiceLocation?> show(
    BuildContext context, {
    ServiceLocation? initialLocation,
    Color primaryColor = const Color(0xFF6366F1),
  }) {
    return showModalBottomSheet<ServiceLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerDialog(
        initialLocation: initialLocation,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final ApiService _api = ApiService();
  List<ServiceLocation> _allLocations = [];
  List<String> _districts = [];
  String _selectedDistrict = 'All';
  String _searchQuery = '';
  bool _loading = true;
  ServiceLocation? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await _api.getServiceLocations();
      final dists = ['All', ...{for (var l in locs) l.district}];
      if (mounted) {
        setState(() {
          _allLocations = locs;
          _districts = dists;
          if (_selected != null) {
            _selectedDistrict = _selected!.district;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ServiceLocation> get _filteredLocations {
    return _allLocations.where((loc) {
      final matchesDist = _selectedDistrict == 'All' ||
          loc.district.toLowerCase() == _selectedDistrict.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          loc.area.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc.pincode.contains(_searchQuery);
      return matchesDist && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.location_on, color: widget.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Service Area',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Karnataka (District & Locality)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              // District Horizontal Selector Tabs
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _districts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final dist = _districts[idx];
                    final isSelected = _selectedDistrict == dist;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedDistrict = dist;
                        _searchQuery = '';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.primaryColor
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dist,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search locality or pincode...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF334155),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Locations List
              Expanded(
                child: _filteredLocations.isEmpty
                    ? const Center(
                        child: Text(
                          'No areas match your query',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _filteredLocations.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.white10,
                          height: 1,
                        ),
                        itemBuilder: (ctx, idx) {
                          final loc = _filteredLocations[idx];
                          final isSelected = _selected?.id == loc.id;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? widget.primaryColor.withValues(alpha: 0.2)
                                    : const Color(0xFF334155),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.pin_drop_outlined,
                                color: isSelected
                                    ? widget.primaryColor
                                    : Colors.white54,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              loc.formattedArea,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${loc.district} • PIN: ${loc.pincode}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: widget.primaryColor,
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              setState(() => _selected = loc);
                              Navigator.pop(context, loc);
                            },
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
