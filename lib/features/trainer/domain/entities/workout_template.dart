import 'package:trainapp/features/trainer/domain/entities/template_exercise.dart';
import 'package:uuid/uuid.dart';

class WorkoutTemplate {
  final String id;
  final String trainerId;
  final String title;
  final String? description;
  final String difficulty;
  final int durationWeeks;
  final bool isPublic;
  final List<TemplateExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutTemplate({
    required this.id,
    required this.trainerId,
    required this.title,
    this.description,
    this.difficulty = 'intermediate',
    this.durationWeeks = 4,
    this.isPublic = false,
    this.exercises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration_weeks': durationWeeks,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      durationWeeks: json['duration_weeks'] as int? ?? 4,
      isPublic: json['is_public'] as bool? ?? false,
      exercises: json['exercises'] != null
          ? (json['exercises'] as List)
              .map((e) => TemplateExercise.fromJson(e))
              .toList()
          : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  WorkoutTemplate copyWith({
    String? id,
    String? trainerId,
    String? title,
    String? description,
    String? difficulty,
    int? durationWeeks,
    bool? isPublic,
    List<TemplateExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      isPublic: isPublic ?? this.isPublic,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}