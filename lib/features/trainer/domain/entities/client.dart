import 'package:trainapp/features/profile/domain/entities/profile.dart';

class Client {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final int? age;
  final double? height;
  final double? weight;
  final List<String>? goals;
  final DateTime? startDate;
  final DateTime? lastActive;
  final int workoutsCompleted;
  final int currentStreak;
  final bool hasActiveSubscription;
  final DateTime? subscriptionEnds;
  final bool isRegistered;  // Новое поле
  final String? phone;      // Новое поле
  final String? telegram;   // Новое поле
  final String? notes;      // Новое поле

  Client({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.age,
    this.height,
    this.weight,
    this.goals,
    this.startDate,
    this.lastActive,
    this.workoutsCompleted = 0,
    this.currentStreak = 0,
    this.hasActiveSubscription = false,
    this.subscriptionEnds,
    this.isRegistered = true,  // По умолчанию зарегистрирован
    this.phone,
    this.telegram,
    this.notes,
  });

  factory Client.fromProfile(Profile profile) {
    return Client(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      avatarUrl: profile.avatarUrl,
      age: profile.age,
      height: profile.height,
      weight: profile.weight,
      goals: profile.goals,
      isRegistered: true,
    );
  }

  // Фабрика для создания незарегистрированного клиента
  factory Client.unregistered({
    required String fullName,
    String? phone,
    String? telegram,
    String? notes,
  }) {
    return Client(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // временный ID
      email: '', // пустой email для незарегистрированных
      fullName: fullName,
      phone: phone,
      telegram: telegram,
      notes: notes,
      isRegistered: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'goals': goals,
      'start_date': startDate?.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'workouts_completed': workoutsCompleted,
      'current_streak': currentStreak,
      'has_active_subscription': hasActiveSubscription,
      'subscription_ends': subscriptionEnds?.toIso8601String(),
      'is_registered': isRegistered,
      'phone': phone,
      'telegram': telegram,
      'notes': notes,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      age: json['age'] as int?,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      goals: json['goals'] != null ? List<String>.from(json['goals']) : null,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active']) : null,
      workoutsCompleted: json['workouts_completed'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      hasActiveSubscription: json['has_active_subscription'] as bool? ?? false,
      subscriptionEnds: json['subscription_ends'] != null 
          ? DateTime.parse(json['subscription_ends']) 
          : null,
      isRegistered: json['is_registered'] as bool? ?? true,
      phone: json['phone'] as String?,
      telegram: json['telegram'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Client copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    int? age,
    double? height,
    double? weight,
    List<String>? goals,
    DateTime? startDate,
    DateTime? lastActive,
    int? workoutsCompleted,
    int? currentStreak,
    bool? hasActiveSubscription,
    DateTime? subscriptionEnds,
    bool? isRegistered,
    String? phone,
    String? telegram,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goals: goals ?? this.goals,
      startDate: startDate ?? this.startDate,
      lastActive: lastActive ?? this.lastActive,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      subscriptionEnds: subscriptionEnds ?? this.subscriptionEnds,
      isRegistered: isRegistered ?? this.isRegistered,
      phone: phone ?? this.phone,
      telegram: telegram ?? this.telegram,
      notes: notes ?? this.notes,
    );
  }
}