import 'provider.dart';

class ServiceRequest {
  final int id;
  final String consumerPhone;
  final String skillRequested;
  final String? description;
  final String location;
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
    required this.skillRequested,
    this.description,
    required this.location,
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

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as int,
      consumerPhone: json['consumer_phone'] as String? ?? '',
      skillRequested: json['skill_requested'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String? ?? '',
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
