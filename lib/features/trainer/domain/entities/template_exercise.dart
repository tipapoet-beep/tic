class TemplateExercise {
  final String id;
  final String templateId;
  final String name;
  final String? description;
  final int sets;
  final int reps;
  final double? weight;
  final int restSeconds;
  final int orderIndex;
  final int dayOfWeek;
  final int weekNumber;

  TemplateExercise({
    required this.id,
    required this.templateId,
    required this.name,
    this.description,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.restSeconds = 60,
    required this.orderIndex,
    this.dayOfWeek = 1,
    this.weekNumber = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_seconds': restSeconds,
      'order_index': orderIndex,
      'day_of_week': dayOfWeek,
      'week_number': weekNumber,
    };
  }

  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    return TemplateExercise(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      restSeconds: json['rest_seconds'] as int? ?? 60,
      orderIndex: json['order_index'] as int,
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      weekNumber: json['week_number'] as int? ?? 1,
    );
  }

  TemplateExercise copyWith({
    String? id,
    String? templateId,
    String? name,
    String? description,
    int? sets,
    int? reps,
    double? weight,
    int? restSeconds,
    int? orderIndex,
    int? dayOfWeek,
    int? weekNumber,
  }) {
    return TemplateExercise(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      description: description ?? this.description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }
}