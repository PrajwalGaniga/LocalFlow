class Consumer {
  final int id;
  final String name;
  final String phone;
  final DateTime? createdAt;

  Consumer({
    required this.id,
    required this.name,
    required this.phone,
    this.createdAt,
  });

  factory Consumer.fromJson(Map<String, dynamic> json) {
    return Consumer(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }
}
