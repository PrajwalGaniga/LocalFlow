import 'service_request.dart';

class NotificationItem {
  final int id;
  final int requestId;
  final int providerId;
  final String status;
  final DateTime notifiedAt;
  final DateTime? respondedAt;
  final ServiceRequest? request;

  NotificationItem({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.status,
    required this.notifiedAt,
    this.respondedAt,
    this.request,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      requestId: json['request_id'] as int,
      providerId: json['provider_id'] as int,
      status: json['status'] as String? ?? 'notified',
      notifiedAt: DateTime.tryParse(json['notified_at'].toString()) ?? DateTime.now(),
      respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at'].toString()) : null,
      request: json['request'] != null ? ServiceRequest.fromJson(json['request'] as Map<String, dynamic>) : null,
    );
  }
}
