import '../../domain/entities/parent_user.dart';

class ParentUserModel extends ParentUser {
  const ParentUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.planName,
    required super.createdAt,
  });

  factory ParentUserModel.fromEntity(ParentUser user) {
    return ParentUserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      planName: user.planName,
      createdAt: user.createdAt,
    );
  }

  factory ParentUserModel.fromJson(Map<String, dynamic> json) {
    return ParentUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      planName: json['planName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'planName': planName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
