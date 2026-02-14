enum UserRole {
  ADMIN,
  SUPERVISOR,
  EMPLOYEE
}

class UserModel {
  final String id;
  final String fullName;
  final UserRole role;
  final String email;
  final bool isActive;

  UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.email,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id_utilisateur'] ?? '',
      fullName: json['nom_complet'] ?? 'Utilisateur',
      role: UserRole.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['role'] as String? ?? 'EMPLOYEE').toUpperCase(),
        orElse: () => UserRole.EMPLOYEE,
      ),
      email: json['email'] ?? '',
      isActive: json['actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_utilisateur': id,
      'nom_complet': fullName,
      'role': role.name,
      'email': email,
      'actif': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    UserRole? role,
    String? email,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }
}
