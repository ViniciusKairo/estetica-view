class AdminUserModel {
  final String id;
  final String nome;
  final String email;
  final bool ativo;
  final DateTime createdAt;

  const AdminUserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.ativo,
    required this.createdAt,
  });

  AdminUserModel copyWith({
    String? id,
    String? nome,
    String? email,
    bool? ativo,
    DateTime? createdAt,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
