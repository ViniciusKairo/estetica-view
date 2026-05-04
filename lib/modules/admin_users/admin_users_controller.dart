import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/create_user_result.dart';
import '../../data/supabase/functions_repository.dart';

class AdminUsersController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final _functions = FunctionsRepository(Supabase.instance.client);

  List<Map<String, dynamic>> _all = [];
  bool loading = false;
  String? errorMessage;

  List<Map<String, dynamic>> get items => _all;

  Future<void> init() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _client
          .from('profiles')
          .select('id, email, nome, is_active, created_at')
          .eq('role', 'admin')
          .order('created_at', ascending: false);

      _all = (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _all = [];
      errorMessage = 'Falha ao carregar administradores.';
      debugPrint('AdminUsersController.init error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<CreateUserResult> addAdmin({
    required String nome,
    required String email,
    required String senha,
    required bool ativo,
  }) async {
    errorMessage = null;

    final result = await _functions.createUserByAdmin(
      role: 'admin',
      email: email.trim(),
      nome: nome.trim(),
      ativo: ativo,
      invite: false,
      password: senha.trim(),
    );

    try {
      await init();
    } catch (e) {
      debugPrint('AdminUsersController.addAdmin refresh warning: $e');
    }

    return result;
  }

  Future<void> toggleStatus(String id) async {
    final admin = _all.firstWhere((a) => a['id'] == id);

    await _client
        .from('profiles')
        .update({'is_active': !(admin['is_active'] as bool? ?? true)})
        .eq('id', id);

    await init();
  }

  Future<void> deleteAdmin(String id) async {
    await _client.from('profiles').delete().eq('id', id);
    await init();
  }
}