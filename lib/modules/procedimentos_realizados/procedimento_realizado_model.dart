enum ProcedimentoStatus { pendenteImagens, emAndamento, concluido, cancelado }

class ProcedimentoRealizadoModel {
  final String id;

  final String pacienteId;
  final String pacienteNome;

  final String medicoId;
  final String medicoNome;

  final String tipoId;
  final String tipoNome;

  final DateTime dataRealizacao;
  final ProcedimentoStatus status;

  final String? observacoes;
  final bool imagesReleasedToPatient;

  const ProcedimentoRealizadoModel({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.medicoId,
    required this.medicoNome,
    required this.tipoId,
    required this.tipoNome,
    required this.dataRealizacao,
    required this.status,
    this.observacoes,
    required this.imagesReleasedToPatient,
  });

  ProcedimentoRealizadoModel copyWith({
    String? pacienteId,
    String? pacienteNome,
    String? medicoId,
    String? medicoNome,
    String? tipoId,
    String? tipoNome,
    DateTime? dataRealizacao,
    ProcedimentoStatus? status,
    String? observacoes,
    bool? imagesReleasedToPatient,
  }) {
    return ProcedimentoRealizadoModel(
      id: id,
      pacienteId: pacienteId ?? this.pacienteId,
      pacienteNome: pacienteNome ?? this.pacienteNome,
      medicoId: medicoId ?? this.medicoId,
      medicoNome: medicoNome ?? this.medicoNome,
      tipoId: tipoId ?? this.tipoId,
      tipoNome: tipoNome ?? this.tipoNome,
      dataRealizacao: dataRealizacao ?? this.dataRealizacao,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      imagesReleasedToPatient:
          imagesReleasedToPatient ?? this.imagesReleasedToPatient,
    );
  }
}
