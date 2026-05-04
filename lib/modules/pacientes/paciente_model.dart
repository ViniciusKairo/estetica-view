class PacienteModel {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final bool ativo;

  const PacienteModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.ativo,
  });

  PacienteModel copyWith({
    String? nome,
    String? email,
    String? telefone,
    bool? ativo,
  }) {
    return PacienteModel(
      id: id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      ativo: ativo ?? this.ativo,
    );
  }
}
