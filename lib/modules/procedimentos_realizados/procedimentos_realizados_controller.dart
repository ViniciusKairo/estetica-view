import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'procedimento_realizado_model.dart';

class RefItem {
  final String id;
  final String label;
  const RefItem(this.id, this.label);
}

String _dbStatusFromApp(ProcedimentoStatus s) {
  switch (s) {
    case ProcedimentoStatus.pendenteImagens:
    case ProcedimentoStatus.emAndamento:
      return 'pendente_imagens';
    case ProcedimentoStatus.concluido:
      return 'concluido';
    case ProcedimentoStatus.cancelado:
      return 'cancelado';
  }
}

ProcedimentoStatus _appStatusFromDb(String? s) {
  switch (s) {
    case 'pendente_imagens':
      return ProcedimentoStatus.pendenteImagens;
    case 'em_andamento':
      return ProcedimentoStatus.emAndamento;
    case 'concluido':
      return ProcedimentoStatus.concluido;
    case 'cancelado':
      return ProcedimentoStatus.cancelado;
    default:
      return ProcedimentoStatus.pendenteImagens;
  }
}

class ProcedimentosRealizadosController extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<RefItem> pacientes = [];
  List<RefItem> medicos = [];
  List<RefItem> tipos = [];

  List<ProcedimentoRealizadoModel> _all = [];
  bool loading = false;
  bool updatingRelease = false;

  String _search = '';
  String _statusFilter = 'ativos';

  String get search => _search;
  String get statusFilter => _statusFilter;

  List<ProcedimentoRealizadoModel> get items {
    Iterable<ProcedimentoRealizadoModel> result = _all;

    if (_statusFilter == 'ativos') {
      result = result.where((e) => e.status != ProcedimentoStatus.cancelado);
    } else if (_statusFilter == 'cancelados') {
      result = result.where((e) => e.status == ProcedimentoStatus.cancelado);
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where(
        (e) =>
            e.pacienteNome.toLowerCase().contains(q) ||
            e.tipoNome.toLowerCase().contains(q) ||
            e.medicoNome.toLowerCase().contains(q),
      );
    }

    final list = result.toList();
    list.sort((a, b) => b.dataRealizacao.compareTo(a.dataRealizacao));
    return list;
  }

  Future<void> init() async {
    loading = true;
    notifyListeners();

    try {
      await Future.wait([_loadRefs(), _loadProcedures()]);
    } catch (e) {
      _all = [];
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRefs() async {
    final [pacRes, medRes, tipRes] = await Future.wait([
      _client.from('pacientes').select('id, profiles(nome)'),
      _client.from('medicos').select('id, profiles(nome)'),
      _client
          .from('tipos_procedimento')
          .select('id, nome')
          .eq('is_active', true),
    ]);

    pacientes = (pacRes as List)
        .map(
          (e) => RefItem(
            e['id'] as String,
            (e['profiles'] as Map?)?['nome'] as String? ?? '',
          ),
        )
        .where((r) => r.label.isNotEmpty)
        .toList();

    medicos = (medRes as List)
        .map(
          (e) => RefItem(
            e['id'] as String,
            (e['profiles'] as Map?)?['nome'] as String? ?? '',
          ),
        )
        .where((r) => r.label.isNotEmpty)
        .toList();

    tipos = (tipRes as List)
        .map((e) => RefItem(e['id'] as String, e['nome'] as String? ?? ''))
        .toList();
  }

  Future<void> _loadProcedures() async {
    final res = await _client
        .from('procedimentos_realizados')
        .select('''
          id,
          paciente_id,
          medico_id,
          tipo_procedimento_id,
          status,
          data_procedimento,
          observacoes,
          acessos_imagem_procedimento!left(is_active),
          pacientes(profiles(nome)),
          medicos(profiles(nome)),
          tipos_procedimento!tipo_procedimento_id(nome)
        ''')
        .order('data_procedimento', ascending: false);

    _all = (res as List).map((e) {
      final pac = e['pacientes'] as Map<String, dynamic>?;
      final med = e['medicos'] as Map<String, dynamic>?;
      final tip = e['tipos_procedimento'] as Map<String, dynamic>?;
      final pacProf = pac?['profiles'] as Map<String, dynamic>?;
      final medProf = med?['profiles'] as Map<String, dynamic>?;
      final dn = e['data_procedimento'] as String?;

      return ProcedimentoRealizadoModel(
        id: e['id'] as String,
        pacienteId: e['paciente_id'] as String,
        pacienteNome: pacProf?['nome'] as String? ?? '',
        medicoId: e['medico_id'] as String,
        medicoNome: medProf?['nome'] as String? ?? '',
        tipoId: e['tipo_procedimento_id'] as String,
        tipoNome: tip?['nome'] as String? ?? '',
        dataRealizacao: dn != null
            ? DateTime.tryParse(dn) ?? DateTime.now()
            : DateTime.now(),
        status: _appStatusFromDb(e['status'] as String?),
        observacoes: e['observacoes'] as String?,
        imagesReleasedToPatient: ((e['acessos_imagem_procedimento'] as List?)?.any((a) => (a as Map)['is_active'] == true)) ?? false,
      );
    }).toList();
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setStatusFilter(String v) {
    _statusFilter = v;
    notifyListeners();
  }

  ProcedimentoRealizadoModel? findById(String id) {
    try {
      return _all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add({
    required String pacienteId,
    required String medicoId,
    required String tipoId,
    required DateTime dataRealizacao,
    required ProcedimentoStatus status,
    String? observacoes,
  }) async {
    await _client.from('procedimentos_realizados').insert({
      'paciente_id': pacienteId,
      'medico_id': medicoId,
      'tipo_procedimento_id': tipoId,
      'data_procedimento': dataRealizacao.toIso8601String().split('T').first,
      'status': _dbStatusFromApp(status),
      'observacoes': observacoes?.trim().isEmpty ?? true
          ? null
          : observacoes?.trim(),
      'created_by': _client.auth.currentUser?.id,
    });

    await init();
  }

  Future<void> update({
    required String id,
    required String pacienteId,
    required String medicoId,
    required String tipoId,
    required DateTime dataRealizacao,
    required ProcedimentoStatus status,
    String? observacoes,
  }) async {
    await _client
        .from('procedimentos_realizados')
        .update({
          'paciente_id': pacienteId,
          'medico_id': medicoId,
          'tipo_procedimento_id': tipoId,
          'data_procedimento': dataRealizacao
              .toIso8601String()
              .split('T')
              .first,
          'status': _dbStatusFromApp(status),
          'observacoes': observacoes?.trim().isEmpty ?? true
              ? null
              : observacoes?.trim(),
        })
        .eq('id', id);

    await init();
  }

  Future<void> changeStatus(String id, ProcedimentoStatus status) async {
    await _client
        .from('procedimentos_realizados')
        .update({'status': _dbStatusFromApp(status)})
        .eq('id', id);

    await init();
  }

  Future<void> setImagesReleasedToPatient({
    required String procedureId,
    required bool released,
  }) async {
    updatingRelease = true;
    notifyListeners();

    try {
      final procedimento = await _client
          .from('procedimentos_realizados')
          .select('paciente_id')
          .eq('id', procedureId)
          .single();

      final pacienteId = procedimento['paciente_id'] as String;

      if (released) {
        await _client.from('acessos_imagem_procedimento').upsert({
          'procedimento_id': procedureId,
          'paciente_id': pacienteId,
          'granted_by': _client.auth.currentUser?.id,
          'granted_at': DateTime.now().toIso8601String(),
          'revoked_by': null,
          'revoked_at': null,
          'is_active': true,
        }, onConflict: 'procedimento_id,paciente_id');
      } else {
        await _client
            .from('acessos_imagem_procedimento')
            .update({
              'is_active': false,
              'revoked_by': _client.auth.currentUser?.id,
              'revoked_at': DateTime.now().toIso8601String(),
            })
            .eq('procedimento_id', procedureId)
            .eq('paciente_id', pacienteId)
            .eq('is_active', true);
      }

      final index = _all.indexWhere((e) => e.id == procedureId);
      if (index != -1) {
        _all[index] = _all[index].copyWith(imagesReleasedToPatient: released);
      }
    } finally {
      updatingRelease = false;
      notifyListeners();
    }
  }
}
