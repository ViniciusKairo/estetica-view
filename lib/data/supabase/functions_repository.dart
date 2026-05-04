import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/create_user_result.dart';

class FunctionsRepository {
  final SupabaseClient _sb;

  FunctionsRepository(this._sb);

  Future<Map<String, dynamic>> _invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _sb.functions.invoke(functionName, body: body);

    debugPrint(
      '[FunctionsRepository] $functionName status=${res.status} data=${res.data}',
    );

    final data = res.data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (res.status != 200) {
      throw Exception('[$functionName] ${res.data}');
    }

    throw Exception(
      '[$functionName] Resposta inesperada da function: ${res.data}',
    );
  }

  Future<CreateUserResult> createUserByAdmin({
    required String role,
    required String email,
    required String nome,
    required bool ativo,
    bool invite = false,
    String? password,
    Map<String, dynamic>? medico,
    Map<String, dynamic>? paciente,
  }) async {
    final normalizedPassword = password?.trim();

    if (!invite && (normalizedPassword == null || normalizedPassword.isEmpty)) {
      throw Exception(
        '[PASSWORD_REQUIRED] Informe a senha inicial do usuário.',
      );
    }

    final body = <String, dynamic>{
      'role': role,
      'email': email.trim(),
      'nome': nome.trim(),
      'ativo': ativo,
      'invite': invite,
      if (!invite) 'password': normalizedPassword,
    };

    if (medico != null) {
      final crm = medico['crm']?.toString().trim();
      final especializacao = medico['especializacao']?.toString().trim();
      final especialidade = medico['especialidade']?.toString().trim();

      body.addAll({
        if (crm != null && crm.isNotEmpty) 'crm': crm,
        if (especializacao != null && especializacao.isNotEmpty)
          'especializacao': especializacao,
        if ((especializacao == null || especializacao.isEmpty) &&
            especialidade != null &&
            especialidade.isNotEmpty)
          'especializacao': especialidade,
        'medico': {
          if (crm != null && crm.isNotEmpty) 'crm': crm,
          if (especializacao != null && especializacao.isNotEmpty)
            'especializacao': especializacao,
          if ((especializacao == null || especializacao.isEmpty) &&
              especialidade != null &&
              especialidade.isNotEmpty)
            'especializacao': especialidade,
        },
      });
    }

    if (paciente != null) {
      final telefone = paciente['telefone']?.toString().trim();
      final cpf = paciente['cpf']?.toString().trim();
      final nascimento = paciente['nascimento']?.toString().trim();

      body.addAll({
        if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
        if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
        if (nascimento != null && nascimento.isNotEmpty)
          'nascimento': nascimento,
        'paciente': paciente,
      });
    }

    final raw = await _invokeFunction('create_user_by_admin', body: body);

    final code = raw['code']?.toString();
    final message = raw['message']?.toString() ?? raw['error']?.toString();

    if (code != null && code.isNotEmpty && code != 'OK') {
      throw Exception('[$code] ${message ?? 'Falha ao criar usuário.'}');
    }

    return CreateUserResult.fromMap(raw);
  }

  Future<CreateUserResult> createPatientByMedico({
    required String nome,
    required String email,
    required String password,
    required bool ativo,
    String? telefone,
  }) async {
    final raw = await _invokeFunction(
      'create_patient_by_medico',
      body: {
        'nome': nome.trim(),
        'email': email.trim(),
        'password': password.trim(),
        'ativo': ativo,
        if (telefone != null && telefone.trim().isNotEmpty)
          'telefone': telefone.trim(),
      },
    );

    final code = raw['code']?.toString();
    final message = raw['message']?.toString() ?? raw['error']?.toString();

    if (code != null && code.isNotEmpty && code != 'OK') {
      throw Exception('[$code] ${message ?? 'Falha ao criar paciente.'}');
    }

    return CreateUserResult.fromMap(raw);
  }

  Future<String> createNotification({
    required String toUser,
    required String title,
    required String body,
    String type = 'sistema',
    String? entityId,
    String? entityType,
  }) async {
    final data = await _invokeFunction(
      'notify',
      body: {
        'to_user': toUser,
        'title': title,
        'body': body,
        'type': type,
        'entity_id': entityId,
        'entity_type': entityType,
      },
    );

    final id = data['notification_id'];
    if (id is String && id.isNotEmpty) {
      return id;
    }

    throw Exception('notify failed: $data');
  }

  Future<void> approveImageRequest({
    required String solicitacaoId,
    required String decision,
    String? motivoReprovacao,
  }) async {
    final data = await _invokeFunction(
      'approve_image_request',
      body: {
        'solicitacao_id': solicitacaoId,
        'decision': decision,
        if (motivoReprovacao != null && motivoReprovacao.trim().isNotEmpty)
          'motivo_reprovacao': motivoReprovacao.trim(),
      },
    );

    final success = data['success'] == true;
    if (!success) {
      throw Exception(
        data['error']?.toString() ??
            data['message']?.toString() ??
            'Falha ao processar solicitação.',
      );
    }
  }

  Future<void> revokeImageAccess({
    required String procedimentoId,
    required String pacienteId,
  }) async {
    final data = await _invokeFunction(
      'revoke_image_access',
      body: {'procedimento_id': procedimentoId, 'paciente_id': pacienteId},
    );

    final success = data['success'] == true;
    if (!success) {
      throw Exception(
        data['error']?.toString() ??
            data['message']?.toString() ??
            'Falha ao revogar acesso.',
      );
    }
  }

  Future<String> signedUrlForImage({
    required String imagemId,
    int expiresInSeconds = 300,
  }) async {
    final data = await _invokeFunction(
      'signed_url_for_image',
      body: {'imagem_id': imagemId, 'expires_in': expiresInSeconds},
    );

    final signedUrl = data['signed_url'];
    if (signedUrl is String && signedUrl.isNotEmpty) {
      return signedUrl;
    }

    final error = data['error']?.toString() ?? data['message']?.toString();
    if (error != null && error.isNotEmpty) {
      throw Exception(error);
    }

    throw Exception('signed_url_for_image failed: $data');
  }
}
