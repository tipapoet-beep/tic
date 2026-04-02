enum EventType {
  workout,
  rest,
  measurement,
  consultation,
}

class CalendarEvent {
  final String id;
  final String userId;
  final String? trainerId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final EventType type;
  final bool isCompleted;
  final String? workoutId;
  final String? colorHex;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.userId,
    this.trainerId,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.type = EventType.workout,
    this.isCompleted = false,
    this.workoutId,
    this.colorHex,
    this.metadata,
    required this.createdAt,
  });

  bool get isAllDay => endDate == null || 
      (endDate!.difference(startDate).inDays >= 1);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trainer_id': trainerId,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'type': type.toString(),
      'is_completed': isCompleted,
      'workout_id': workoutId,
      'color_hex': colorHex,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      userId: json['user_id'],
      trainerId: json['trainer_id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      type: _parseEventType(json['type']),
      isCompleted: json['is_completed'] ?? false,
      workoutId: json['workout_id'],
      colorHex: json['color_hex'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static EventType _parseEventType(String? type) {
    if (type == null) return EventType.workout;
    if (type.contains('workout')) return EventType.workout;
    if (type.contains('rest')) return EventType.rest;
    if (type.contains('measurement')) return EventType.measurement;
    if (type.contains('consultation')) return EventType.consultation;
    return EventType.workout;
  }

  CalendarEvent copyWith({
    String? id,
    String? userId,
    String? trainerId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    bool? isCompleted,
    String? workoutId,
    String? colorHex,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trainerId: trainerId ?? this.trainerId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      workoutId: workoutId ?? this.workoutId,
      colorHex: colorHex ?? this.colorHex,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}