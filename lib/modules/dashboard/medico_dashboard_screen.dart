import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/action_card.dart';
import '../../ui/widgets/section_title.dart';

class MedicoDashboardScreen extends StatelessWidget {
  const MedicoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final scheme = Theme.of(context).colorScheme;
    final userEmail = authController.session?.user.email ?? '';
    final userName = _displayNameFromEmail(userEmail);

    return AppScaffold(
      title: 'Painel médico',
      showBack: false,
      child: ListView(
        children: [
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
                            roleLabel: 'Médico',
                            subtitle:
                                'Concentre os fluxos principais do atendimento em uma interface mais limpa e objetiva.',
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: _MiniSummaryCard(
                            title: 'Área clínica',
                            subtitle:
                                'Acesso rápido para pacientes, procedimentos, aprovações e conta.',
                            icon: Icons.local_hospital_outlined,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeBlock(
                          iconBg: scheme.primary.withOpacity(0.10),
                          iconColor: scheme.primary,
                          name: userName,
                          roleLabel: 'Médico',
                          subtitle:
                              'Concentre os fluxos principais do atendimento em uma interface mais limpa e objetiva.',
                        ),
                        const SizedBox(height: 12),
                        const _MiniSummaryCard(
                          title: 'Área clínica',
                          subtitle:
                              'Acesso rápido para pacientes, procedimentos, aprovações e conta.',
                          icon: Icons.local_hospital_outlined,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle(
            title: 'Ações rápidas',
            subtitle:
                'Cadastre, execute procedimentos e gerencie sua conta com mais clareza operacional.',
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: isWide ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 2.45 : 2.35,
            children: [
              ActionCard(
                icon: Icons.people_alt_rounded,
                title: 'Pacientes',
                subtitle: 'Gerencie pacientes sob sua responsabilidade.',
                onTap: () => context.push('/pacientes'),
                highlight: true,
              ),
              ActionCard(
                icon: Icons.category_rounded,
                title: 'Tipos de procedimentos',
                subtitle: 'Mantenha o catálogo disponível.',
                onTap: () => context.push('/tipos-procedimento'),
              ),
              ActionCard(
                icon: Icons.medical_services_rounded,
                title: 'Procedimentos realizados',
                subtitle: 'Registre execuções e acompanhe imagens.',
                onTap: () => context.push('/procedimentos-realizados'),
              ),
              ActionCard(
                icon: Icons.fact_check_rounded,
                title: 'Aprovações',
                subtitle: 'Analise pedidos de acesso às imagens.',
                onTap: () => context.push('/solicitacoes-imagens'),
              ),
              //ActionCard(
              //  icon: Icons.manage_accounts_rounded,
              //  title: 'Minha conta',
              //  subtitle: 'Atualize seus dados e altere sua senha.',
              //  onTap: () => context.push('/profile'),
              //),
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

class _MiniSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _MiniSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.35,
                    fontSize: 13,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
