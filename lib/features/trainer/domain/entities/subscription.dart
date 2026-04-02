class Subscription {
  final String id;
  final String clientId;
  final String trainerId;
  final String planName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.paymentStatus = 'pending',
    this.notes,
    required this.createdAt,
  });

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
  bool get isExpired => endDate.isBefore(DateTime.now());
  int get daysLeft => endDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'trainer_id': trainerId,
      'plan_name': planName,
      'price': price,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      planName: json['plan_name'] as String,
      price: (json['price'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] as String? ?? 'active',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Subscription copyWith({
    String? id,
    String? clientId,
    String? trainerId,
    String? planName,
    double? price,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      trainerId: trainerId ?? this.trainerId,
      planName: planName ?? this.planName,
      price: price ?? this.price,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}