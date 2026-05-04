enum SolicitacaoStatus { pendente, aprovada, reprovada }

class SolicitacaoImagemModel {
  final String id;
  final String procedimentoId;
  final String pacienteId;
  final String pacienteNome;
  final String tipoNome;
  final DateTime criadaEm;
  final SolicitacaoStatus status;
  final String? observacao;
  final String? motivoReprovacao;

  const SolicitacaoImagemModel({
    required this.id,
    required this.procedimentoId,
    required this.pacienteId,
    required this.pacienteNome,
    required this.tipoNome,
    required this.criadaEm,
    required this.status,
    this.observacao,
    this.motivoReprovacao,
  });
}
