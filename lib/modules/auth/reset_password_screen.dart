import 'dart:async';

import 'package:flutter/foundation.dart';
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

  StreamSubscription<AuthState>? _authSub;

  bool obscure1 = true;
  bool obscure2 = true;
  bool loading = false;
  bool success = false;
  bool preparingSession = true;
  bool sessionReady = false;
  bool linkInvalid = false;

  @override
  void initState() {
    super.initState();
    _listenRecoveryEvents();
    _prepareRecoveryFlow();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _listenRecoveryEvents() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery ||
          (event == AuthChangeEvent.signedIn && session != null)) {
        setState(() {
          sessionReady = true;
          preparingSession = false;
          linkInvalid = false;
        });
      }
    });
  }

  Future<void> _prepareRecoveryFlow() async {
    final auth = Supabase.instance.client.auth;

    try {
      if (auth.currentSession != null) {
        if (!mounted) return;
        setState(() {
          sessionReady = true;
          preparingSession = false;
          linkInvalid = false;
        });
        return;
      }

      if (kIsWeb) {
        final uri = Uri.base;
        final code = (uri.queryParameters['code'] ?? '').trim();
        final tokenHash = (uri.queryParameters['token_hash'] ?? '').trim();
        final type = (uri.queryParameters['type'] ?? '').trim().toLowerCase();

        if (code.isNotEmpty) {
          await auth.exchangeCodeForSession(code);
        } else if (type == 'recovery' && tokenHash.isNotEmpty) {
          await auth.verifyOTP(type: OtpType.recovery, tokenHash: tokenHash);
        }

        for (var i = 0; i < 20; i++) {
          if (auth.currentSession != null) break;
          await Future.delayed(const Duration(milliseconds: 250));
        }

        final prepared = auth.currentSession != null;

        if (!mounted) return;
        setState(() {
          sessionReady = prepared;
          preparingSession = false;
          linkInvalid = !prepared;
        });

        return;
      }

      for (var i = 0; i < 24; i++) {
        if (auth.currentSession != null) break;
        if (sessionReady) break;
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final prepared = auth.currentSession != null || sessionReady;

      if (!mounted) return;
      setState(() {
        sessionReady = prepared;
        preparingSession = false;
        linkInvalid = !prepared;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString();

      setState(() {
        sessionReady = false;
        preparingSession = false;
        linkInvalid = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.contains('Code verifier could not be found')
                ? 'O link foi aberto sem a sessão de recuperação esperada pelo navegador. Solicite um novo link e abra no mesmo navegador em que fez a solicitação.'
                : 'Falha ao validar link de recuperação: $e',
          ),
        ),
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
      await authController.signOut();

      if (!mounted) return;

      setState(() => success = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Senha atualizada com sucesso. Faça login com a nova senha.',
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      context.go('/login');
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
                            linkInvalid: linkInvalid,
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
                            linkInvalid: linkInvalid,
                            onToggle1: () =>
                                setState(() => obscure1 = !obscure1),
                            onToggle2: () =>
                                setState(() => obscure2 = !obscure2),
                            onSave: _saveNewPassword,
                            onRetry: _prepareRecoveryFlow,
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
                          linkInvalid: linkInvalid,
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
                          linkInvalid: linkInvalid,
                          onToggle1: () => setState(() => obscure1 = !obscure1),
                          onToggle2: () => setState(() => obscure2 = !obscure2),
                          onSave: _saveNewPassword,
                          onRetry: _prepareRecoveryFlow,
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
  final bool linkInvalid;

  const _ResetIntro({
    required this.iconBg,
    required this.iconColor,
    required this.success,
    required this.sessionReady,
    required this.linkInvalid,
  });

  @override
  Widget build(BuildContext context) {
    final title = success
        ? 'Senha redefinida'
        : sessionReady
        ? 'Defina uma nova senha'
        : linkInvalid
        ? 'Link inválido ou expirado'
        : 'Validação pendente';

    final subtitle = success
        ? 'A atualização foi concluída. Agora faça login com a nova senha.'
        : sessionReady
        ? 'Informe e confirme a nova senha para concluir a recuperação.'
        : linkInvalid
        ? 'Não foi possível preparar a sessão de recuperação. Solicite um novo link.'
        : 'Estamos aguardando a sessão de recuperação ser preparada. Se nada acontecer, tente validar novamente.';

    final icon = success
        ? Icons.verified_rounded
        : sessionReady
        ? Icons.lock_reset_rounded
        : linkInvalid
        ? Icons.error_outline_rounded
        : Icons.hourglass_top_rounded;

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
  final bool linkInvalid;
  final VoidCallback onToggle1;
  final VoidCallback onToggle2;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const _ResetForm({
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.obscure1,
    required this.obscure2,
    required this.success,
    required this.loading,
    required this.sessionReady,
    required this.linkInvalid,
    required this.onToggle1,
    required this.onToggle2,
    required this.onSave,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ir para o login'),
          ),
        ],
      );
    }

    if (!sessionReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(linkInvalid ? 'Tentar novamente' : 'Validar novamente'),
          ),
          const SizedBox(height: 10),
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: passwordCtrl,
          obscureText: obscure1,
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
          onPressed: loading ? null : onSave,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar nova senha'),
        ),
      ],
    );
  }
}
