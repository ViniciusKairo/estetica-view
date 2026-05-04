import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/functions_repository.dart';
import '../models/create_user_result.dart';

class AdminUsersService {
  final FunctionsRepository _functions;

  AdminUsersService(SupabaseClient client)
    : _functions = FunctionsRepository(client);

  Future<CreateUserResult> createAdmin({
    required String nome,
    required String email,
    bool invite = true,
    bool ativo = true,
  }) {
    return _functions.createUserByAdmin(
      role: 'admin',
      nome: nome,
      email: email,
      ativo: ativo,
      invite: invite,
    );
  }

  Future<CreateUserResult> createMedico({
    required String nome,
    required String email,
    required String crm,
    String? especialidade,
    bool invite = true,
    bool ativo = true,
  }) {
    return _functions.createUserByAdmin(
      role: 'medico',
      nome: nome,
      email: email,
      ativo: ativo,
      invite: invite,
      medico: {'crm': crm, 'especialidade': especialidade},
    );
  }

  Future<CreateUserResult> createPaciente({
    required String nome,
    required String email,
    String? telefone,
    String? nascimentoIso,
    String? cpf,
    bool invite = true,
    bool ativo = true,
  }) {
    return _functions.createUserByAdmin(
      role: 'paciente',
      nome: nome,
      email: email,
      ativo: ativo,
      invite: invite,
      paciente: {'telefone': telefone, 'nascimento': nascimentoIso, 'cpf': cpf},
    );
  }
}
