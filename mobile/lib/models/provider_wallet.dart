class WalletTransaction {
  final int requestId;
  final String consumerPhone;
  final String skill;
  final String location;
  final int amount;
  final String status;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final int? rating;

  WalletTransaction({
    required this.requestId,
    required this.consumerPhone,
    required this.skill,
    required this.location,
    required this.amount,
    required this.status,
    this.paidAt,
    this.completedAt,
    this.rating,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      requestId: json['request_id'] ?? 0,
      consumerPhone: json['consumer_phone'] ?? '',
      skill: json['skill'] ?? '',
      location: json['location'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? 'Completed',
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      rating: json['rating'],
    );
  }
}

class ProviderWallet {
  final int providerId;
  final String providerName;
  final int totalEarnings;
  final int availableBalance;
  final int jobsCompleted;
  final double ratingAvg;
  final List<WalletTransaction> transactions;

  ProviderWallet({
    required this.providerId,
    required this.providerName,
    required this.totalEarnings,
    required this.availableBalance,
    required this.jobsCompleted,
    required this.ratingAvg,
    required this.transactions,
  });

  factory ProviderWallet.fromJson(Map<String, dynamic> json) {
    final list = (json['transactions'] as List?) ?? [];
    return ProviderWallet(
      providerId: json['provider_id'] ?? 0,
      providerName: json['provider_name'] ?? '',
      totalEarnings: json['total_earnings'] ?? 0,
      availableBalance: json['available_balance'] ?? 0,
      jobsCompleted: json['jobs_completed'] ?? 0,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 5.0,
      transactions: list.map((t) => WalletTransaction.fromJson(t)).toList(),
    );
  }
}
