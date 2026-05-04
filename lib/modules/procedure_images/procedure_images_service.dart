import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/supabase/functions_repository.dart';
import 'procedure_image_model.dart';

class ProcedureImagesService {
  final SupabaseClient _sb;
  final FunctionsRepository _functions;

  ProcedureImagesService(SupabaseClient client)
    : _sb = client,
      _functions = FunctionsRepository(client);

  static const String _bucket = 'procedure-images';
  static const Uuid _uuid = Uuid();

  Future<List<ProcedureImageModel>> listByProcedure(String procedureId) async {
    final res = await _sb
        .from('imagens_procedimento')
        .select('''
          id,
          procedimento_id,
          tipo_imagem,
          storage_path,
          tamanho_bytes,
          mime_type,
          created_at,
          uploaded_by,
          is_active
        ''')
        .eq('procedimento_id', procedureId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => ProcedureImageModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ProcedureImageModel> uploadImage({
    required String procedureId,
    required String imageType,
    required XFile originalFile,
  }) async {
    if (imageType != 'antes' && imageType != 'depois') {
      throw Exception('Tipo de imagem inválido.');
    }

    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuário não autenticado.');
    }

    final originalBytes = await originalFile.readAsBytes();
    if (originalBytes.isEmpty) {
      throw Exception('Arquivo de imagem vazio.');
    }

    final compressed = await _compressImage(originalBytes);
    if (compressed == null || compressed.isEmpty) {
      throw Exception('Falha ao comprimir imagem.');
    }

    final fileName = '${_uuid.v4()}.jpg';
    final storagePath = '$procedureId/$imageType/$fileName';

    await _sb.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          compressed,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    final inserted = await _sb
        .from('imagens_procedimento')
        .insert({
          'procedimento_id': procedureId,
          'tipo_imagem': imageType,
          'storage_path': storagePath,
          'tamanho_bytes': compressed.length,
          'mime_type': 'image/jpeg',
          'uploaded_by': userId,
          'is_active': true,
        })
        .select('''
          id,
          procedimento_id,
          tipo_imagem,
          storage_path,
          tamanho_bytes,
          mime_type,
          created_at,
          uploaded_by,
          is_active
        ''')
        .single();

    return ProcedureImageModel.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<Uint8List?> _compressImage(Uint8List bytes) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      debugPrint('Erro ao comprimir imagem: $e');
      return null;
    }
  }

  Future<String> getSignedUrl({
    required String imageId,
    int expiresInSeconds = 600,
  }) async {
    return _functions.signedUrlForImage(
      imagemId: imageId,
      expiresInSeconds: expiresInSeconds,
    );
  }

  Future<void> deactivateImage(String imageId) async {
    await _sb
        .from('imagens_procedimento')
        .update({'is_active': false})
        .eq('id', imageId);
  }
}
