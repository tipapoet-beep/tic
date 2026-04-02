class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime date;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? biceps;
  final double? thighs;
  final double? calves;
  final double? shoulders;
  final double? neck;
  final double? bodyFat;
  final String? notes;
  final DateTime createdAt;

  BodyMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.biceps,
    this.thighs,
    this.calves,
    this.shoulders,
    this.neck,
    this.bodyFat,
    this.notes,
    required this.createdAt, double? bicepsLeft, double? bicepsRight, double? thighsLeft, double? thighsRight,
  });

  BodyMeasurement copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    double? chest,
    double? waist,
    double? hips,
    double? biceps,
    double? thighs,
    double? calves,
    double? shoulders,
    double? neck,
    double? bodyFat,
    String? notes,
    DateTime? createdAt,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      biceps: biceps ?? this.biceps,
      thighs: thighs ?? this.thighs,
      calves: calves ?? this.calves,
      shoulders: shoulders ?? this.shoulders,
      neck: neck ?? this.neck,
      bodyFat: bodyFat ?? this.bodyFat,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'biceps': biceps,
      'thighs': thighs,
      'calves': calves,
      'shoulders': shoulders,
      'neck': neck,
      'body_fat': bodyFat,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date']),
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      chest: json['chest'] != null ? (json['chest'] as num).toDouble() : null,
      waist: json['waist'] != null ? (json['waist'] as num).toDouble() : null,
      hips: json['hips'] != null ? (json['hips'] as num).toDouble() : null,
      biceps: json['biceps'] != null ? (json['biceps'] as num).toDouble() : null,
      thighs: json['thighs'] != null ? (json['thighs'] as num).toDouble() : null,
      calves: json['calves'] != null ? (json['calves'] as num).toDouble() : null,
      shoulders: json['shoulders'] != null ? (json['shoulders'] as num).toDouble() : null,
      neck: json['neck'] != null ? (json['neck'] as num).toDouble() : null,
      bodyFat: json['body_fat'] != null ? (json['body_fat'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  double? get bicepsLeft => null;

  double? get bicepsRight => null;

  double? get thighsLeft => null;

  double? get thighsRight => null;

  get calvesLeft => null;

  get calvesRight => null;
}