import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.avatarUrl,
    super.age,
    super.height,
    super.weight,
    super.goals,
    super.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      avatarUrl: json['avatar_url'] as String?,
      age: json['age'] as int?,
      height: json['height'] != null 
          ? double.parse(json['height'].toString()) 
          : null,
      weight: json['weight'] != null 
          ? double.parse(json['weight'].toString()) 
          : null,
      goals: json['goals'] != null 
          ? List<String>.from(json['goals']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
  
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
      'created_at': createdAt?.toIso8601String(),
    };
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? avatarUrl,
    int? age,
    double? height,
    double? weight,
    List<String>? goals,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goals: goals ?? this.goals,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}