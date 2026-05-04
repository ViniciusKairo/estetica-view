import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase/functions_repository.dart';
import 'solicitacao_imagem_model.dart';

SolicitacaoStatus _appStatusFromDb(String? s) {
  switch (s) {
    case 'aprovada':
      return SolicitacaoStatus.aprovada;
    case 'reprovada':
      return SolicitacaoStatus.reprovada;
    case 'pendente':
    default:
      return SolicitacaoStatus.pendente;
  }
}

class SolicitacoesImagensController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final _functions = FunctionsRepository(Supabase.instance.client);

  List<SolicitacaoImagemModel> _all = [];
  bool loading = false;
  String _search = '';
  String _statusFilter = 'todas';

  String get search => _search;
  String get statusFilter => _statusFilter;

  List<SolicitacaoImagemModel> get items {
    Iterable<SolicitacaoImagemModel> result = _all;

    switch (_statusFilter) {
      case 'pendentes':
        result = result.where((e) => e.status == SolicitacaoStatus.pendente);
        break;
      case 'aprovadas':
        result = result.where((e) => e.status == SolicitacaoStatus.aprovada);
        break;
      case 'reprovadas':
        result = result.where((e) => e.status == SolicitacaoStatus.reprovada);
        break;
      default:
        break;
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where(
        (e) =>
            e.pacienteNome.toLowerCase().contains(q) ||
            e.tipoNome.toLowerCase().contains(q) ||
            e.procedimentoId.toLowerCase().contains(q),
      );
    }

    final list = result.toList();
    list.sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
    return list;
  }

  Future<void> init() async {
    loading = true;
    notifyListeners();

    try {
      final res = await _client
          .from('solicitacoes_imagem')
          .select('''
            id,
            procedimento_id,
            paciente_id,
            status,
            observacao,
            motivo_reprovacao,
            requested_at,
            procedimentos_realizados!procedimento_id(
              id,
              tipo_procedimento_id,
              tipos_procedimento!tipo_procedimento_id(nome)
            ),
            pacientes!paciente_id(
              id,
              profiles(nome)
            )
          ''')
          .order('requested_at', ascending: false);

      _all = (res as List)
          .map<SolicitacaoImagemModel>((e) {
            final row = Map<String, dynamic>.from(e as Map);

            final proc = row['procedimentos_realizados'] is Map<String, dynamic>
                ? row['procedimentos_realizados'] as Map<String, dynamic>
                : row['procedimentos_realizados'] is Map
                ? Map<String, dynamic>.from(
                    row['procedimentos_realizados'] as Map,
                  )
                : <String, dynamic>{};

            final tipo = proc['tipos_procedimento'] is Map<String, dynamic>
                ? proc['tipos_procedimento'] as Map<String, dynamic>
                : proc['tipos_procedimento'] is Map
                ? Map<String, dynamic>.from(proc['tipos_procedimento'] as Map)
                : <String, dynamic>{};

            final paciente = row['pacientes'] is Map<String, dynamic>
                ? row['pacientes'] as Map<String, dynamic>
                : row['pacientes'] is Map
                ? Map<String, dynamic>.from(row['pacientes'] as Map)
                : <String, dynamic>{};

            final profile = paciente['profiles'] is Map<String, dynamic>
                ? paciente['profiles'] as Map<String, dynamic>
                : paciente['profiles'] is Map
                ? Map<String, dynamic>.from(paciente['profiles'] as Map)
                : <String, dynamic>{};

            final created =
                DateTime.tryParse(row['requested_at']?.toString() ?? '') ??
                DateTime.now();

            return SolicitacaoImagemModel(
              id: row['id']?.toString() ?? '',
              procedimentoId: row['procedimento_id']?.toString() ?? '',
              pacienteId: row['paciente_id']?.toString() ?? '',
              pacienteNome:
                  profile['nome']?.toString() ?? 'Paciente não informado',
              tipoNome: tipo['nome']?.toString() ?? 'Procedimento',
              criadaEm: created,
              status: _appStatusFromDb(row['status']?.toString()),
              observacao: row['observacao']?.toString(),
              motivoReprovacao: row['motivo_reprovacao']?.toString(),
            );
          })
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (e) {
      _all = [];
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setStatusFilter(String v) {
    _statusFilter = v;
    notifyListeners();
  }

  Future<void> approve(String solicitacaoId) async {
    await _functions.approveImageRequest(
      solicitacaoId: solicitacaoId,
      decision: 'aprovada',
    );
    await init();
  }

  Future<void> reject(String solicitacaoId, {String? motivo}) async {
    await _functions.approveImageRequest(
      solicitacaoId: solicitacaoId,
      decision: 'reprovada',
      motivoReprovacao: motivo,
    );
    await init();
  }
}
