class ParentUser {
  const ParentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.planName,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String planName;
  final DateTime createdAt;

  ParentUser copyWith({
    String? id,
    String? name,
    String? email,
    String? planName,
    DateTime? createdAt,
  }) {
    return ParentUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      planName: planName ?? this.planName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
