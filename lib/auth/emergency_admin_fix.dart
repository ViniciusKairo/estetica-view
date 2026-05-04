// EMERGENCY ADMIN FIX - USE APENAS PARA DEBUG
// Importe este arquivo temporariamente no auth_controller.dart

// Lista de emails que devem ser tratados como admin
const List<String> adminEmails = [
  'vinicius@email.com', // Substitua pelo seu email real
];

bool isAdminEmail(String? email) {
  if (email == null) return false;
  return adminEmails.any(
    (adminEmail) => adminEmail.toLowerCase() == email.toLowerCase(),
  );
}

// Substitua o método _fetchRoleSafe() temporariamente por:
/*
Future<AppRole> _fetchRoleSafe() async {
  final user = _client.auth.currentUser;
  if (user == null) return AppRole.paciente;

  // EMERGENCY FIX: Força admin para emails específicos
  if (isAdminEmail(user.email)) {
    debugPrint('EMERGENCY: Forcing admin role for ${user.email}');
    return AppRole.admin;
  }

  // Resto do código normal...
  try {
    final res = await _client
        .from('profiles')
        .select('role, email, nome, is_active')
        .eq('id', user.id)
        .single()
        .timeout(const Duration(seconds: 6));

    final r = (res['role'] as String?)?.toLowerCase().trim();
    
    switch (r) {
      case 'admin':
        return AppRole.admin;
      case 'medico':
        return AppRole.medico;
      default:
        return AppRole.paciente;
    }
  } catch (e) {
    return AppRole.paciente;
  }
}
*/
