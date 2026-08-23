class ServiceLocation {
  final int id;
  final String state;
  final String district;
  final String areaName;
  final String pincode;

  ServiceLocation({
    required this.id,
    required this.state,
    required this.district,
    required this.areaName,
    required this.pincode,
  });

  String get area => areaName;
  String get displayName => '$areaName, $district';
  String get shortName => areaName;
  String get formattedArea => '$areaName • $district';

  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    return ServiceLocation(
      id: json['id'] as int? ?? 0,
      state: json['state'] as String? ?? 'Karnataka',
      district: json['district'] as String? ?? '',
      areaName: json['area_name'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state': state,
      'district': district,
      'area_name': areaName,
      'pincode': pincode,
    };
  }
}
