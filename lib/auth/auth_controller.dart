import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { admin, medico, paciente }

class AuthController extends ChangeNotifier {
  AuthController() {
    _bootstrap();
  }

  final _client = Supabase.instance.client;

  Session? session;
  AppRole? role;
  bool booting = true;

  StreamSubscription<AuthState>? _sub;

  bool get isLoggedIn => session != null;

  Future<void> _bootstrap() async {
    debugPrint('=== AUTH BOOTSTRAP START ===');

    session = _client.auth.currentSession;

    _sub = _client.auth.onAuthStateChange.listen((data) async {
      session = data.session;

      if (session == null) {
        role = null;
        notifyListeners();
        return;
      }

      try {
        role = await _fetchRole();
      } catch (e) {
        debugPrint('Role fetch error: $e');
        role = null;
      }

      notifyListeners();
    });

    if (session != null) {
      try {
        role = await _fetchRole();
      } catch (e) {
        debugPrint('Initial role fetch error: $e');
        role = null;
      }
    }

    booting = false;
    notifyListeners();

    debugPrint('=== AUTH BOOTSTRAP END ===');
  }

  Future<AppRole> _fetchRole() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final res = await _client
        .from('profiles')
        .select('role, is_active')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 6));

    if (res == null) {
      throw Exception('Profile not found');
    }

    if (res['is_active'] != true) {
      throw Exception('Profile inactive');
    }

    final roleStr = (res['role'] as String?)?.toLowerCase().trim();

    switch (roleStr) {
      case 'admin':
        return AppRole.admin;
      case 'medico':
        return AppRole.medico;
      case 'paciente':
        return AppRole.paciente;
      default:
        throw Exception('Invalid role: $roleStr');
    }
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendResetPasswordEmail(String email) async {
    final redirectTo = kIsWeb
        ? '${Uri.base.origin}/reset-password'
        : 'gestaofotos://login-callback';

    print('RESET REDIRECT -> $redirectTo');
    print('RESET EMAIL -> ${email.trim()}');

    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword({required String newPassword}) async {
    final trimmed = newPassword.trim();
    if (trimmed.length < 6) {
      throw Exception('A senha deve ter pelo menos 6 caracteres.');
    }

    await _client.auth.updateUser(UserAttributes(password: trimmed));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
