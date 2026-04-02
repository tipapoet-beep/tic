class Profile {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final int? age;
  final double? height;
  final double? weight;
  final List<String>? goals;
  final String? bio;
  final String? city;
  final String? experienceLevel;
  final int? trainingFrequency;
  final String? phone;
  final String? instagram;
  final String? telegram;
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.age,
    this.height,
    this.weight,
    this.goals,
    this.bio,
    this.city,
    this.experienceLevel,
    this.trainingFrequency,
    this.phone,
    this.instagram,
    this.telegram,
    this.notificationsEnabled = true,
    this.createdAt,
    this.updatedAt, List<String>? specialties, required experienceYears,
  });
  
  // Метод copyWith с телом
  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? avatarUrl,
    int? age,
    double? height,
    double? weight,
    List<String>? goals,
    String? bio,
    String? city,
    String? experienceLevel,
    int? trainingFrequency,
    String? phone,
    String? instagram,
    String? telegram,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt, int? experienceYears, List<String>? specialties, String? education, List<String>? achievements, List<String>? awards,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goals: goals ?? this.goals,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      trainingFrequency: trainingFrequency ?? this.trainingFrequency,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      telegram: telegram ?? this.telegram,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, experienceYears: null,
    );
  }
  
  // Метод toJson с телом
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'avatar_url': avatarUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'goals': goals,
      'bio': bio,
      'city': city,
      'experience_level': experienceLevel,
      'training_frequency': trainingFrequency,
      'phone': phone,
      'instagram': instagram,
      'telegram': telegram,
      'notifications_enabled': notificationsEnabled,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  // Фабричный метод fromJson с телом
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      avatarUrl: json['avatar_url'] as String?,
      age: json['age'] as int?,
      height: json['height'] != null ? double.parse(json['height'].toString()) : null,
      weight: json['weight'] != null ? double.parse(json['weight'].toString()) : null,
      goals: json['goals'] != null ? List<String>.from(json['goals']) : null,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      experienceLevel: json['experience_level'] as String?,
      trainingFrequency: json['training_frequency'] as int?,
      phone: json['phone'] as String?,
      instagram: json['instagram'] as String?,
      telegram: json['telegram'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null, experienceYears: null,
    );
  }

  get achievements => null;

  get education => null;

  get awards => null;

  get experienceYears => null;

  get specialties => null;

  get trainerName => null;
}