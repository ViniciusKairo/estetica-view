import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../auth/auth_controller.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/action_card.dart';
import '../../ui/widgets/section_title.dart';

class PacienteDashboardScreen extends StatelessWidget {
  const PacienteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final scheme = Theme.of(context).colorScheme;
    final userEmail = authController.session?.user.email ?? '';
    final userName = _displayNameFromEmail(userEmail);

    return AppScaffold(
      title: 'Área do paciente',
      showBack: false,
      child: ListView(
        children: [
          if (authController.role == AppRole.admin) ...[
            Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  color: const Color(0xFFFEF2F2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFB91C1C),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Inconsistência de redirecionamento',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Você está em uma área de paciente, mas o perfil atual aparenta ser administrativo.',
                      style: TextStyle(
                        color: Color(0xFF7F1D1D),
                        height: 1.4,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Ir para painel admin'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _WelcomeBlock(
                            iconBg: scheme.primary.withOpacity(0.10),
                            iconColor: scheme.primary,
                            name: userName,
                            roleLabel: 'Paciente',
                            subtitle:
                                'Acompanhe suas solicitações, visualize procedimentos vinculados e acesse suas imagens quando liberadas.',
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(child: _PatientInfoCard()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeBlock(
                          iconBg: scheme.primary.withOpacity(0.10),
                          iconColor: scheme.primary,
                          name: userName,
                          roleLabel: 'Paciente',
                          subtitle:
                              'Acompanhe suas solicitações, visualize procedimentos vinculados e acesse suas imagens quando liberadas.',
                        ),
                        const SizedBox(height: 12),
                        const _PatientInfoCard(),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle(
            title: 'Minha área clínica',
            subtitle:
                'Acompanhe solicitações, procedimentos vinculados e notificações.',
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: isWide ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 2.7 : 2.35,
            children: [
              ActionCard(
                icon: Icons.add_photo_alternate_rounded,
                title: 'Solicitar Imagens',
                subtitle:
                    'Solicite acesso às fotos de antes e depois dos seus tratamentos.',
                onTap: () => context.push('/requests'),
                highlight: true,
              ),
              ActionCard(
                icon: Icons.image_rounded,
                title: 'Meus procedimentos',
                subtitle:
                    'Veja apenas procedimentos em que você foi vinculado.',
                onTap: () => context.push('/procedures'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayNameFromEmail(String email) {
    if (email.trim().isEmpty || !email.contains('@')) return 'usuário';
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'usuário';

    final cleaned = local.replaceAll(RegExp(r'[._\\-]+'), ' ').trim();
    if (cleaned.isEmpty) return 'usuário';

    return cleaned
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}

class _WelcomeBlock extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final String name;
  final String roleLabel;
  final String subtitle;

  const _WelcomeBlock({
    required this.iconBg,
    required this.iconColor,
    required this.name,
    required this.roleLabel,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.waving_hand_rounded, color: iconColor, size: 22),
        ),
        const SizedBox(height: 12),
        Text(
          'Bem-vindo, $name',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        _RoleBadge(label: roleLabel),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            height: 1.4,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _PatientInfoCard extends StatelessWidget {
  const _PatientInfoCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: scheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acompanhamento pessoal',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Você visualiza apenas informações vinculadas ao seu perfil e não realiza cadastros administrativos.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.35,
                    fontSize: 12.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;

  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
