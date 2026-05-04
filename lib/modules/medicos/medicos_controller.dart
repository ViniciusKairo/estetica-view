import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/create_user_result.dart';
import '../../data/supabase/functions_repository.dart';
import 'medico_model.dart';

class MedicosController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final _functions = FunctionsRepository(Supabase.instance.client);

  List<MedicoModel> _all = [];
  String _search = '';
  String _statusFilter = 'ativos';
  bool loading = false;
  String? errorMessage;

  final Map<String, String> _medicoProfileIds = {};

  String get search => _search;
  String get statusFilter => _statusFilter;

  List<MedicoModel> get items {
    Iterable<MedicoModel> result = _all;

    if (_statusFilter == 'ativos') {
      result = result.where((m) => m.ativo);
    } else if (_statusFilter == 'inativos') {
      result = result.where((m) => !m.ativo);
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      result = result.where((m) {
        return m.nome.toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q) ||
            m.crm.toLowerCase().contains(q) ||
            m.especializacao.toLowerCase().contains(q);
      });
    }

    return result.toList();
  }

  Future<void> init() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _client
          .from('medicos')
          .select(
            'id, profile_id, crm, especializacao, profiles(nome, email, is_active)',
          )
          .order('crm');

      final rows = (res as List);

      _all = rows.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final profRaw = row['profiles'];
        final prof = profRaw is Map<String, dynamic>
            ? profRaw
            : Map<String, dynamic>.from((profRaw as Map?) ?? {});

        return MedicoModel(
          id: row['id'] as String,
          nome: (prof['nome'] ?? '') as String,
          email: (prof['email'] ?? '') as String,
          crm: (row['crm'] ?? '') as String,
          especializacao: (row['especializacao'] ?? '') as String,
          ativo: prof['is_active'] as bool? ?? true,
        );
      }).toList();

      _medicoProfileIds.clear();
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        _medicoProfileIds[row['id'] as String] = row['profile_id'] as String;
      }
    } catch (e) {
      _all = [];
      errorMessage = 'Falha ao carregar médicos.';
      debugPrint('MedicosController.init error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  Future<CreateUserResult> addMedico({
    required String nome,
    required String email,
    required String crm,
    required String especializacao,
    required bool ativo,
    required String password,
  }) async {
    errorMessage = null;

    final result = await _functions.createUserByAdmin(
      role: 'medico',
      email: email.trim(),
      nome: nome.trim(),
      ativo: ativo,
      invite: false,
      password: password.trim(),
      medico: {
        'crm': crm.trim(),
        'especializacao': especializacao.trim().isEmpty
            ? null
            : especializacao.trim(),
      },
    );

    try {
      await init();
    } catch (e) {
      debugPrint('MedicosController.addMedico refresh warning: $e');
    }

    return result;
  }

  Future<void> updateMedico({
    required String id,
    required String nome,
    required String email,
    required String crm,
    required String especializacao,
    required bool ativo,
  }) async {
    final profileId = _medicoProfileIds[id];
    if (profileId == null) throw Exception('Médico não encontrado');

    await _client
        .from('profiles')
        .update({
          'nome': nome.trim(),
          'email': email.trim(),
          'is_active': ativo,
        })
        .eq('id', profileId);

    await _client
        .from('medicos')
        .update({
          'crm': crm.trim(),
          'especializacao': especializacao.trim().isEmpty
              ? null
              : especializacao.trim(),
        })
        .eq('id', id);

    await init();
  }

  Future<void> toggleStatus(String id) async {
    final profileId = _medicoProfileIds[id];
    if (profileId == null) return;

    final m = _all.firstWhere((x) => x.id == id);

    await _client
        .from('profiles')
        .update({'is_active': !m.ativo})
        .eq('id', profileId);

    await init();
  }

  MedicoModel? findById(String id) {
    try {
      return _all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}