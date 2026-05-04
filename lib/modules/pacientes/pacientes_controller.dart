import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_router.dart';
import '../../data/models/create_user_result.dart';
import '../../data/supabase/functions_repository.dart';
import '../../auth/auth_controller.dart';
import 'paciente_model.dart';

class PacientesController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final _functions = FunctionsRepository(Supabase.instance.client);

  List<PacienteModel> _data = [];
  final Map<String, String> _pacienteProfileIds = {};

  String _search = '';
  String _status = 'ativos';
  bool loading = false;
  String? errorMessage;

  String get search => _search;
  String get status => _status;

  List<PacienteModel> get items {
    Iterable<PacienteModel> result = _data;

    if (_status == 'ativos') {
      result = result.where((e) => e.ativo);
    } else if (_status == 'inativos') {
      result = result.where((e) => !e.ativo);
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      result = result.where(
        (p) =>
            p.nome.toLowerCase().contains(q) ||
            p.email.toLowerCase().contains(q) ||
            p.telefone.toLowerCase().contains(q),
      );
    }

    return result.toList();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatus(String value) {
    _status = value;
    notifyListeners();
  }

  Future<void> init() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _client
          .from('pacientes')
          .select('id, profile_id, telefone, profiles(nome, email, is_active)')
          .order('created_at', ascending: false);

      final rows = (res as List);

      _data = rows.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final profRaw = row['profiles'];
        final prof = profRaw is Map<String, dynamic>
            ? profRaw
            : Map<String, dynamic>.from((profRaw as Map?) ?? {});

        return PacienteModel(
          id: row['id'] as String,
          nome: (prof['nome'] ?? '') as String,
          email: (prof['email'] ?? '') as String,
          telefone: (row['telefone'] as String?) ?? '',
          ativo: prof['is_active'] as bool? ?? true,
        );
      }).toList();

      _pacienteProfileIds.clear();
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        _pacienteProfileIds[row['id'] as String] = row['profile_id'] as String;
      }
    } catch (e) {
      _data = [];
      errorMessage = 'Falha ao carregar pacientes.';
      debugPrint('PacientesController.init error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<CreateUserResult> addPaciente({
    required String nome,
    required String email,
    required String telefone,
    required bool ativo,
    required String password,
  }) async {
    errorMessage = null;

    final currentRole = authController.role;
    late final CreateUserResult result;

    if (currentRole == AppRole.admin) {
      result = await _functions.createUserByAdmin(
        role: 'paciente',
        email: email.trim(),
        nome: nome.trim(),
        ativo: ativo,
        password: password.trim(),
        paciente: {if (telefone.trim().isNotEmpty) 'telefone': telefone.trim()},
      );
    } else if (currentRole == AppRole.medico) {
      result = await _functions.createPatientByMedico(
        nome: nome.trim(),
        email: email.trim(),
        password: password.trim(),
        ativo: ativo,
        telefone: telefone.trim().isEmpty ? null : telefone.trim(),
      );
    } else {
      throw Exception('Perfil sem permissão para cadastrar paciente.');
    }

    try {
      await init();
    } catch (e) {
      debugPrint('PacientesController.addPaciente refresh warning: $e');
    }

    return result;
  }

  Future<void> updatePaciente({
    required String id,
    required String nome,
    required String email,
    required String telefone,
    required bool ativo,
  }) async {
    final profileId = _pacienteProfileIds[id];
    if (profileId == null) throw Exception('Paciente não encontrado');

    await _client
        .from('profiles')
        .update({'nome': nome.trim(), 'is_active': ativo})
        .eq('id', profileId);

    await _client
        .from('pacientes')
        .update({'telefone': telefone.trim().isEmpty ? null : telefone.trim()})
        .eq('id', id);

    await init();
  }

  Future<void> toggle(String id) async {
    final profileId = _pacienteProfileIds[id];
    if (profileId == null) return;

    final p = _data.firstWhere((x) => x.id == id);

    await _client
        .from('profiles')
        .update({'is_active': !p.ativo})
        .eq('id', profileId);

    await init();
  }

  PacienteModel? findById(String id) {
    try {
      return _data.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadCpfByPacienteId(String id) async {
    return null;
  }
}
