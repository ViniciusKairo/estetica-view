class MedicoModel {
  final String id;
  final String nome;
  final String email;
  final String crm;
  final String especializacao;
  final bool ativo;

  const MedicoModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.crm,
    required this.especializacao,
    required this.ativo,
  });

  MedicoModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? crm,
    String? especializacao,
    bool? ativo,
  }) {
    return MedicoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      crm: crm ?? this.crm,
      especializacao: especializacao ?? this.especializacao,
      ativo: ativo ?? this.ativo,
    );
  }
}
