import 'package:trainapp/features/trainer/domain/entities/client.dart';


class ScheduleSlot {
  final String id;
  final String trainerId;
  final String? clientId; // для зарегистрированных
  final String? unregisteredClientId; // для незарегистрированных
  final Client? client; // для отображения
  final String? unregisteredClientName; // имя незарегистрированного клиента
  final DateTime startTime;
  final DateTime endTime;
  final String? workoutId;
  final String? workoutTitle;
  final bool isCompleted;
  final String? notes;

  ScheduleSlot({
    required this.id,
    required this.trainerId,
    this.clientId,
    this.unregisteredClientId,
    this.client,
    this.unregisteredClientName,
    required this.startTime,
    required this.endTime,
    this.workoutId,
    this.workoutTitle,
    this.isCompleted = false,
    this.notes,
  }) : assert(clientId != null || unregisteredClientId != null, 
         'Either clientId or unregisteredClientId must be provided');

  String get displayName {
    if (client != null) return client!.fullName;
    if (unregisteredClientName != null) return unregisteredClientName!;
    return 'Клиент';
  }

  int get hour => startTime.hour;
  int get dayOfWeek => startTime.weekday;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'client_id': clientId,
      'unregistered_client_id': unregisteredClientId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'workout_id': workoutId,
      'workout_title': workoutTitle,
      'is_completed': isCompleted,
      'notes': notes,
    };
  }

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'],
      trainerId: json['trainer_id'],
      clientId: json['client_id'],
      unregisteredClientId: json['unregistered_client_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      workoutId: json['workout_id'],
      workoutTitle: json['workout_title'],
      isCompleted: json['is_completed'] ?? false,
      notes: json['notes'],
    );
  }

  ScheduleSlot copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    String? unregisteredClientId,
    Client? client,
    String? unregisteredClientName,
    DateTime? startTime,
    DateTime? endTime,
    String? workoutId,
    String? workoutTitle,
    bool? isCompleted,
    String? notes,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      unregisteredClientId: unregisteredClientId ?? this.unregisteredClientId,
      client: client ?? this.client,
      unregisteredClientName: unregisteredClientName ?? this.unregisteredClientName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      workoutId: workoutId ?? this.workoutId,
      workoutTitle: workoutTitle ?? this.workoutTitle,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }
}