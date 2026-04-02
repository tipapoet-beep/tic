class ProgressPhoto {
  final String id;
  final String userId;
  final DateTime date;
  final String photoUrl;
  final String? thumbnailUrl;
  final String? notes;
  final DateTime createdAt;

  ProgressPhoto({
    required this.id,
    required this.userId,
    required this.date,
    required this.photoUrl,
    this.thumbnailUrl,
    this.notes,
    required this.createdAt,
  });

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? photoUrl,
    String? thumbnailUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      photoUrl: photoUrl ?? this.photoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'photo_url': photoUrl,
      'thumbnail_url': thumbnailUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date']),
      photoUrl: json['photo_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}