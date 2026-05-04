import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../ui/app_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();

  bool loading = false;
  bool sent = false;

  int cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = emailCtrl.text.trim();

    if (email.isEmpty) {
      _showSnack('Informe o e-mail.');
      return;
    }

    if (!email.contains('@')) {
      _showSnack('Informe um e-mail válido.');
      return;
    }

    if (loading || cooldownSeconds > 0) return;

    setState(() => loading = true);

    try {
      await authController.sendResetPasswordEmail(email);

      if (!mounted) return;

      setState(() => sent = true);
      _startCooldown(60);

      _showSnack('Se o e-mail existir, o link de recuperação foi enviado.');
    } catch (e) {
      if (!mounted) return;

      final message = _friendlyResetError(e);
      _showSnack(message);

      if (_isRateLimitError(e)) {
        _startCooldown(60);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _isRateLimitError(Object e) {
    final raw = e.toString().toLowerCase();
    return raw.contains('429') ||
        raw.contains('rate limit') ||
        raw.contains('over_email_send_rate_limit') ||
        raw.contains('email rate limit exceeded');
  }

  String _friendlyResetError(Object e) {
    final raw = e.toString().toLowerCase();

    if (_isRateLimitError(e)) {
      return 'Você solicitou recuperação recentemente. Aguarde um pouco antes de tentar novamente.';
    }

    if (raw.contains('invalid email')) {
      return 'O e-mail informado é inválido.';
    }

    if (raw.contains('network') ||
        raw.contains('socket') ||
        raw.contains('timeout')) {
      return 'Falha de conexão. Verifique a internet e tente novamente.';
    }

    return 'Não foi possível enviar o e-mail de recuperação agora.';
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();

    setState(() {
      cooldownSeconds = seconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          cooldownSeconds = 0;
        });
      } else {
        setState(() {
          cooldownSeconds--;
        });
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _buttonLabel() {
    if (loading) return 'Enviando...';
    if (cooldownSeconds > 0) return 'Aguarde ${cooldownSeconds}s';
    return 'Enviar link';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Recuperar senha',
      showNotificationsAction: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _IntroPanel(
                            iconBg: scheme.primary.withOpacity(0.10),
                            iconColor: scheme.primary,
                            sent: sent,
                            cooldownSeconds: cooldownSeconds,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _FormPanel(
                            emailCtrl: emailCtrl,
                            loading: loading,
                            sent: sent,
                            cooldownSeconds: cooldownSeconds,
                            buttonLabel: _buttonLabel(),
                            onSend: _sendReset,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _IntroPanel(
                          iconBg: scheme.primary.withOpacity(0.10),
                          iconColor: scheme.primary,
                          sent: sent,
                          cooldownSeconds: cooldownSeconds,
                        ),
                        const SizedBox(height: 18),
                        _FormPanel(
                          emailCtrl: emailCtrl,
                          loading: loading,
                          sent: sent,
                          cooldownSeconds: cooldownSeconds,
                          buttonLabel: _buttonLabel(),
                          onSend: _sendReset,
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

class _IntroPanel extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final bool sent;
  final int cooldownSeconds;

  const _IntroPanel({
    required this.iconBg,
    required this.iconColor,
    required this.sent,
    required this.cooldownSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final title = sent ? 'Solicitação enviada' : 'Recuperação de acesso';

    final subtitle = sent
        ? 'Se o e-mail existir, as instruções serão enviadas. No app mobile, abra o link no próprio celular.'
        : 'Informe o e-mail cadastrado para receber o link de redefinição de senha.';

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
            child: Icon(
              sent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
          ),
          if (cooldownSeconds > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                'Novo envio disponível em ${cooldownSeconds}s.',
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final bool sent;
  final int cooldownSeconds;
  final String buttonLabel;
  final VoidCallback onSend;

  const _FormPanel({
    required this.emailCtrl,
    required this.loading,
    required this.sent,
    required this.cooldownSeconds,
    required this.buttonLabel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = loading || cooldownSeconds > 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey('$sent-$cooldownSeconds-$loading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailCtrl,
            enabled: !loading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: blocked ? null : onSend,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(buttonLabel),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Voltar para o login'),
          ),
        ],
      ),
    );
  }
}
