import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  bool loading = true;
  bool saving = false;

  String? _email;
  String? _role;
  bool _isActive = true;
  bool _hasPacientePhone = false;
  String? _pacienteId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      _email = user.email;

      final profileRow = await _client
          .from('profiles')
          .select('id, nome, role, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow == null) {
        throw Exception('Perfil não encontrado.');
      }

      _nomeCtrl.text = (profileRow['nome'] ?? '').toString();
      _role = (profileRow['role'] ?? '').toString();
      _isActive = profileRow['is_active'] == true;

      final pacienteRow = await _client
          .from('pacientes')
          .select('id, telefone')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (pacienteRow != null) {
        _hasPacientePhone = true;
        _pacienteId = pacienteRow['id']?.toString();
        _telefoneCtrl.text = (pacienteRow['telefone'] ?? '').toString();
      } else {
        _hasPacientePhone = false;
        _pacienteId = null;
        _telefoneCtrl.clear();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => saving = true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      await _client
          .from('profiles')
          .update({'nome': _nomeCtrl.text.trim()})
          .eq('id', user.id);

      if (_hasPacientePhone && _pacienteId != null) {
        await _client
            .from('pacientes')
            .update({'telefone': _telefoneCtrl.text.trim()})
            .eq('id', _pacienteId!);
      }

      if (!mounted) return;
      _showSnack('Dados atualizados com sucesso.');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _roleLabel(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'medico':
        return 'Médico';
      case 'paciente':
        return 'Paciente';
      default:
        return 'Usuário';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Minha conta',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              Icons.manage_accounts_rounded,
                              color: scheme.primary,
                              size: AppIconSize.md,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minha conta',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                const Text(
                                  'Atualize seus dados básicos e gerencie sua credencial de acesso.',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nomeCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(
                                Icons.person_rounded,
                                size: AppIconSize.sm,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe seu nome.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            initialValue: _email ?? '',
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: AppIconSize.sm,
                              ),
                            ),
                          ),
                          if (_hasPacientePhone) ...[
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _telefoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                prefixIcon: Icon(
                                  Icons.phone_rounded,
                                  size: AppIconSize.sm,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              _SoftBadge(
                                label: _roleLabel(_role),
                                color: scheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _SoftBadge(
                                label: _isActive ? 'Ativo' : 'Inativo',
                                color: _isActive
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Credenciais',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Para alterar sua senha, use a tela específica de credenciais.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/change-password'),
                            icon: const Icon(
                              Icons.lock_reset_rounded,
                              size: AppIconSize.sm,
                            ),
                            label: const Text('Alterar senha'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: FilledButton(
                          onPressed: saving ? null : _save,
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SoftBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs + 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
