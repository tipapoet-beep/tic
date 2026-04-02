import 'package:equatable/equatable.dart';

class ClientWorkoutExercise extends Equatable {
  final String id;
  final String clientProgramId;
  final String templateExerciseId;
  final String name;
  final int sets;
  final int reps;
  final double? weight;
  final int orderIndex;
  final int dayOfWeek;
  final int weekNumber;
  final int? restSeconds;
  final String? notes;
  final DateTime? completedAt;
  final bool isCompleted;

  const ClientWorkoutExercise({
    required this.id,
    required this.clientProgramId,
    required this.templateExerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    required this.orderIndex,
    required this.dayOfWeek,
    required this.weekNumber,
    this.restSeconds,
    this.notes,
    this.completedAt,
    this.isCompleted = false,
  });

  factory ClientWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return ClientWorkoutExercise(
      id: json['id'],
      clientProgramId: json['client_program_id'],
      templateExerciseId: json['template_exercise_id'],
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      orderIndex: json['order_index'],
      dayOfWeek: json['day_of_week'],
      weekNumber: json['week_number'],
      restSeconds: json['rest_seconds'],
      notes: json['notes'],
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_program_id': clientProgramId,
      'template_exercise_id': templateExerciseId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'order_index': orderIndex,
      'day_of_week': dayOfWeek,
      'week_number': weekNumber,
      'rest_seconds': restSeconds,
      'notes': notes,
      'completed_at': completedAt?.toIso8601String(),
      'is_completed': isCompleted,
    };
  }

  ClientWorkoutExercise copyWith({
    String? id,
    String? clientProgramId,
    String? templateExerciseId,
    String? name,
    int? sets,
    int? reps,
    double? weight,
    int? orderIndex,
    int? dayOfWeek,
    int? weekNumber,
    int? restSeconds,
    String? notes,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return ClientWorkoutExercise(
      id: id ?? this.id,
      clientProgramId: clientProgramId ?? this.clientProgramId,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      orderIndex: orderIndex ?? this.orderIndex,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      weekNumber: weekNumber ?? this.weekNumber,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientProgramId,
    templateExerciseId,
    name,
    sets,
    reps,
    weight,
    orderIndex,
    dayOfWeek,
    weekNumber,
    restSeconds,
    notes,
    completedAt,
    isCompleted,
  ];
}