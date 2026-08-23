class Provider {
  final int id;
  final String name;
  final String phone;
  final String skill;
  final String location;
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
    required this.location,
    this.rateMin,
    this.rateMax,
    required this.availabilityStatus,
    required this.verificationLevel,
    required this.ratingAvg,
    required this.ratingCount,
    required this.jobsCompleted,
    this.createdAt,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      skill: json['skill'] as String? ?? '',
      location: json['location'] as String? ?? '',
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
      'location': location,
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
