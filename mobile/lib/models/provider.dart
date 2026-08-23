import 'service_location.dart';

class Provider {
  final int id;
  final String name;
  final String phone;
  final String skill;
  final int? locationId;
  final ServiceLocation? location;
  final int? rateMin;
  final int? rateMax;
  final String availabilityStatus;
  final String verificationLevel;
  final double ratingAvg;
  final int ratingCount;
  final int jobsCompleted;
  final DateTime? createdAt;

  Provider({
    required this.id,
    required this.name,
    required this.phone,
    required this.skill,
    this.locationId,
    this.location,
    this.rateMin,
    this.rateMax,
    required this.availabilityStatus,
    required this.verificationLevel,
    required this.ratingAvg,
    required this.ratingCount,
    required this.jobsCompleted,
    this.createdAt,
  });

  String get locationName => location?.areaName ?? 'Local Area';
  String get locationFull => location?.formattedArea ?? locationName;

  factory Provider.fromJson(Map<String, dynamic> json) {
    ServiceLocation? loc;
    if (json['location'] is Map<String, dynamic>) {
      loc = ServiceLocation.fromJson(json['location'] as Map<String, dynamic>);
    } else if (json['location'] is String) {
      loc = ServiceLocation(
        id: json['location_id'] as int? ?? 1,
        state: 'Karnataka',
        district: 'Bengaluru Urban',
        areaName: json['location'] as String,
        pincode: '',
      );
    }

    return Provider(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      skill: json['skill'] as String? ?? '',
      locationId: json['location_id'] as int? ?? loc?.id,
      location: loc,
      rateMin: json['rate_min'] as int?,
      rateMax: json['rate_max'] as int?,
      availabilityStatus: json['availability_status'] as String? ?? 'available_now',
      verificationLevel: json['verification_level'] as String? ?? 'registered',
      ratingAvg: (json['rating_avg'] is num) ? (json['rating_avg'] as num).toDouble() : 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      jobsCompleted: json['jobs_completed'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'skill': skill,
      'location_id': locationId,
      'rate_min': rateMin,
      'rate_max': rateMax,
      'availability_status': availabilityStatus,
      'verification_level': verificationLevel,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'jobs_completed': jobsCompleted,
    };
  }
}
