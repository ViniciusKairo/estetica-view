class TipoProcedimentoModel {
  final String id;
  final String nome;
  final String descricao;
  final bool ativo;

  const TipoProcedimentoModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.ativo,
  });

  TipoProcedimentoModel copyWith({
    String? nome,
    String? descricao,
    bool? ativo,
  }) {
    return TipoProcedimentoModel(
      id: id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
    );
  }
}
