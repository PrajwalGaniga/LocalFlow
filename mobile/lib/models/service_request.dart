import 'provider.dart';
import 'service_location.dart';

class ServiceRequest {
  final int id;
  final String consumerPhone;
  final String? consumerName;
  final String skillRequested;
  final String? description;
  final int? locationId;
  final ServiceLocation? location;
  final int? preferredProviderId;
  final String status; // pending, matched, completed, cancelled
  final String paymentStatus; // unpaid, paid
  final DateTime? paidAt;
  final int? providerId;
  final Provider? provider;
  final int? rating;
  final String? ratingComment;
  final DateTime? createdAt;
  final DateTime? matchedAt;
  final DateTime? completedAt;

  ServiceRequest({
    required this.id,
    required this.consumerPhone,
    this.consumerName,
    required this.skillRequested,
    this.description,
    this.locationId,
    this.location,
    this.preferredProviderId,
    required this.status,
    this.paymentStatus = 'unpaid',
    this.paidAt,
    this.providerId,
    this.provider,
    this.rating,
    this.ratingComment,
    this.createdAt,
    this.matchedAt,
    this.completedAt,
  });

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
  bool get isMatched => status.toLowerCase() == 'matched';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get locationName => location?.areaName ?? 'Local Area';
  String get locationFull => location?.formattedArea ?? locationName;

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
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

    return ServiceRequest(
      id: json['id'] as int,
      consumerPhone: json['consumer_phone'] as String? ?? '',
      consumerName: json['consumer_name'] as String?,
      skillRequested: json['skill_requested'] as String? ?? '',
      description: json['description'] as String?,
      locationId: json['location_id'] as int? ?? loc?.id,
      location: loc,
      preferredProviderId: json['preferred_provider_id'] as int?,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
      providerId: json['provider_id'] as int?,
      provider: json['provider'] != null ? Provider.fromJson(json['provider'] as Map<String, dynamic>) : null,
      rating: json['rating'] as int?,
      ratingComment: json['rating_comment'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      matchedAt: json['matched_at'] != null ? DateTime.tryParse(json['matched_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
    );
  }
}
