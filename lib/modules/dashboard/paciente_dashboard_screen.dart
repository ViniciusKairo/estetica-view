import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_router.dart';
import '../../ui/app_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;
  bool loading = false;
  bool success = false;
  bool preparingSession = true;
  bool sessionReady = false;

  @override
  void initState() {
    super.initState();
    _handleRecoverySession();
  }

  @override
  void dispose() {
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRecoverySession() async {
    try {
      final uri = Uri.base;

      final code = uri.queryParameters['code'];

      if (code != null && code.isNotEmpty) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
      } else {
        final fragmentParams = uri.fragment.isNotEmpty
            ? Uri.splitQueryString(uri.fragment)
            : <String, String>{};

        final accessToken = fragmentParams['access_token'];
        final refreshToken = fragmentParams['refresh_token'];

        if (accessToken != null &&
            accessToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty) {
          await Supabase.instance.client.auth.setSession(refreshToken);
        }
      }

      final hasSession = Supabase.instance.client.auth.currentSession != null;

      if (!mounted) return;

      setState(() {
        sessionReady = hasSession;
        preparingSession = false;
      });

      if (!hasSession) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível preparar a sessão de recuperação. Solicite um novo link.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sessionReady = false;
        preparingSession = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao validar link de recuperação: $e')),
      );
    }
  }

  Future<void> _saveNewPassword() async {
    final password = passwordCtrl.text.trim();
    final confirm = confirmPasswordCtrl.text.trim();

    if (!sessionReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sessão de recuperação não encontrada. Solicite um novo link.',
          ),
        ),
      );
      return;
    }

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha os dois campos.')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }

    setState(() => loading = true);

    try {
      await authController.updatePassword(newPassword: password);

      if (!mounted) return;

      setState(() => success = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao atualizar senha: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Redefinir senha',
      showNotificationsAction: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: preparingSession
                  ? const _PreparingRecoveryView()
                  : isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ResetIntro(
                            iconBg: scheme.primary.withOpacity(0.10),
                            iconColor: scheme.primary,
                            success: success,
                            sessionReady: sessionReady,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _ResetForm(
                            passwordCtrl: passwordCtrl,
                            confirmPasswordCtrl: confirmPasswordCtrl,
                            obscure1: obscure1,
                            obscure2: obscure2,
                            success: success,
                            loading: loading,
                            sessionReady: sessionReady,
                            onToggle1: () =>
                                setState(() => obscure1 = !obscure1),
                            onToggle2: () =>
                                setState(() => obscure2 = !obscure2),
                            onSave: _saveNewPassword,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ResetIntro(
                          iconBg: scheme.primary.withOpacity(0.10),
                          iconColor: scheme.primary,
                          success: success,
                          sessionReady: sessionReady,
                        ),
                        const SizedBox(height: 18),
                        _ResetForm(
                          passwordCtrl: passwordCtrl,
                          confirmPasswordCtrl: confirmPasswordCtrl,
                          obscure1: obscure1,
                          obscure2: obscure2,
                          success: success,
                          loading: loading,
                          sessionReady: sessionReady,
                          onToggle1: () => setState(() => obscure1 = !obscure1),
                          onToggle2: () => setState(() => obscure2 = !obscure2),
                          onSave: _saveNewPassword,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparingRecoveryView extends StatelessWidget {
  const _PreparingRecoveryView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(height: 16),
          Text(
            'Preparando recuperação de senha...',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Aguarde enquanto validamos o link recebido por e-mail.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ResetIntro extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final bool success;
  final bool sessionReady;

  const _ResetIntro({
    required this.iconBg,
    required this.iconColor,
    required this.success,
    required this.sessionReady,
  });

  @override
  Widget build(BuildContext context) {
    final title = !sessionReady
        ? 'Link inválido ou expirado'
        : success
        ? 'Senha redefinida'
        : 'Defina uma nova senha';

    final subtitle = !sessionReady
        ? 'Não foi possível preparar a sessão de recuperação. Solicite um novo link de redefinição.'
        : success
        ? 'A atualização foi concluída. Agora você já pode voltar ao login.'
        : 'Crie uma nova senha para recuperar o acesso ao sistema com segurança.';

    final icon = !sessionReady
        ? Icons.error_outline_rounded
        : success
        ? Icons.verified_rounded
        : Icons.lock_reset_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ResetForm extends StatelessWidget {
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final bool obscure1;
  final bool obscure2;
  final bool success;
  final bool loading;
  final bool sessionReady;
  final VoidCallback onToggle1;
  final VoidCallback onToggle2;
  final VoidCallback onSave;

  const _ResetForm({
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.obscure1,
    required this.obscure2,
    required this.success,
    required this.loading,
    required this.sessionReady,
    required this.onToggle1,
    required this.onToggle2,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: !sessionReady
          ? Column(
              key: const ValueKey('invalid-session'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/forgot'),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: const Text('Solicitar novo link'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Voltar para o login'),
                ),
              ],
            )
          : Column(
              key: ValueKey(success),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure1,
                  enabled: !success,
                  decoration: InputDecoration(
                    labelText: 'Nova senha',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      onPressed: onToggle1,
                      icon: Icon(
                        obscure1
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: obscure2,
                  enabled: !success,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nova senha',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: onToggle2,
                      icon: Icon(
                        obscure2
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: loading || success ? null : onSave,
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar nova senha'),
                ),
                if (success) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Ir para o login'),
                  ),
                ],
              ],
            ),
    );
  }
}
