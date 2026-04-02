import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final int? age;
  final double? height;
  final double? weight;
  final List<String>? goals;
  final DateTime? createdAt;
  
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.age,
    this.height,
    this.weight,
    this.goals,
    this.createdAt,
  });
  
  bool get isTrainer => role == 'trainer';
  bool get isClient => role == 'client';
  
  @override
  List<Object?> get props => [
    id, email, fullName, role, avatarUrl, 
    age, height, weight, goals, createdAt
  ];
}