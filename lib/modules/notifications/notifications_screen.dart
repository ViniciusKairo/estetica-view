import 'package:flutter/material.dart';

import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Placeholder: depois vira lista do Supabase (read_at, created_at etc.)
  final List<Map<String, dynamic>> items = [];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Notificações',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _HeaderBlock(
                            iconBg: scheme.primary.withOpacity(0.10),
                            iconColor: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: _InfoPanel()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderBlock(
                          iconBg: scheme.primary.withOpacity(0.10),
                          iconColor: scheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const _InfoPanel(),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.notifications_off_rounded,
                    title: 'Nada por aqui',
                    message:
                        'Quando houver atualizações, elas aparecerão aqui.',
                    actionLabel: 'Recarregar',
                    onAction: () => setState(() {}),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final title = (n['title'] ?? 'Notificação') as String;
                      final body = (n['body'] ?? 'Detalhes...') as String;
                      final createdAt =
                          (n['created_at'] ?? 'Agora há pouco') as String;

                      return _NotificationCard(
                        title: title,
                        body: body,
                        createdAt: createdAt,
                        onTap: () {},
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;

  const _HeaderBlock({required this.iconBg, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.notifications_none_rounded, color: iconColor),
        ),
        const SizedBox(height: 16),
        Text(
          'Central de notificações',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Acompanhe alertas, movimentações e atualizações relevantes do sistema em uma visualização mais limpa.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.45),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _MiniInfoRow(
            icon: Icons.info_outline_rounded,
            iconColor: scheme.primary,
            title: 'Leitura rápida',
            subtitle: 'Eventos relevantes devem ser fáceis de escanear.',
          ),
          const SizedBox(height: 12),
          _MiniInfoRow(
            icon: Icons.mark_email_unread_outlined,
            iconColor: scheme.primary,
            title: 'Sem poluição visual',
            subtitle: 'Foco em contexto, horário e prioridade da mensagem.',
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _MiniInfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final String title;
  final String body;
  final String createdAt;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.onTap,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: hovering ? 1.01 : 1,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(hovering ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.body,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.createdAt,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
