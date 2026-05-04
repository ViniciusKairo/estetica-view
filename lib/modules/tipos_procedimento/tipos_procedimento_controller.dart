import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tipo_procedimento_model.dart';

class TiposProcedimentoController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final String _table = 'tipos_procedimento';

  List<TipoProcedimentoModel> _data = [];
  bool loading = false;
  String _search = '';
  String _status = 'ativos';

  String get search => _search;
  String get status => _status;

  List<TipoProcedimentoModel> get items {
    Iterable<TipoProcedimentoModel> result = _data;

    if (_status == 'ativos') {
      result = result.where((e) => e.ativo);
    } else if (_status == 'inativos') {
      result = result.where((e) => !e.ativo);
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      result = result.where(
        (e) =>
            e.nome.toLowerCase().contains(q) ||
            (e.descricao?.toLowerCase().contains(q) ?? false),
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
    notifyListeners();

    try {
      final res = await _client.from(_table).select().order('nome');
      _data = (res as List)
          .map(
            (e) => TipoProcedimentoModel(
              id: e['id'] as String,
              nome: e['nome'] as String,
              descricao: (e['descricao'] as String?) ?? '',
              ativo: (e['is_active'] as bool?) ?? true,
            ),
          )
          .toList();
    } catch (e) {
      _data = [];
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addTipo({
    required String nome,
    required String descricao,
    required bool ativo,
  }) async {
    await _client.from(_table).insert({
      'nome': nome.trim(),
      'descricao': descricao.trim().isEmpty ? null : descricao.trim(),
      'is_active': ativo,
    });

    await init();
  }

  Future<void> updateTipo({
    required String id,
    required String nome,
    required String descricao,
    required bool ativo,
  }) async {
    await _client
        .from(_table)
        .update({
          'nome': nome.trim(),
          'descricao': descricao.trim().isEmpty ? null : descricao.trim(),
          'is_active': ativo,
        })
        .eq('id', id);

    await init();
  }

  Future<void> toggle(String id) async {
    final item = _data.firstWhere((e) => e.id == id);
    await _client.from(_table).update({'is_active': !item.ativo}).eq('id', id);
    await init();
  }

  TipoProcedimentoModel? findById(String id) {
    try {
      return _data.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
