class ProcedureImageModel {
  final String id;
  final String procedureId;
  final String imageType;
  final String storagePath;
  final int? fileSize;
  final String? mimeType;
  final DateTime? createdAt;
  final String? createdBy;
  final bool isActive;

  const ProcedureImageModel({
    required this.id,
    required this.procedureId,
    required this.imageType,
    required this.storagePath,
    this.fileSize,
    this.mimeType,
    this.createdAt,
    this.createdBy,
    required this.isActive,
  });

  factory ProcedureImageModel.fromMap(Map<String, dynamic> map) {
    return ProcedureImageModel(
      id: map['id'] as String,
      procedureId: map['procedimento_id'] as String,
      imageType: (map['tipo_imagem'] as String?) ?? '',
      storagePath: (map['storage_path'] as String?) ?? '',
      fileSize: (map['tamanho_bytes'] as num?)?.toInt(),
      mimeType: map['mime_type'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      createdBy: map['uploaded_by'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}
