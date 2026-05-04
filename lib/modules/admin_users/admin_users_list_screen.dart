import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';
import 'admin_users_controller.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  final controller = AdminUsersController();

  @override
  void initState() {
    super.initState();
    controller.init();
    controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  Future<void> _goToCreate() async {
    await context.push('/admin-users/create');
    if (mounted) {
      await controller.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 820;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Administradores',
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
                        SizedBox(
                          width: 220,
                          child: FilledButton.icon(
                            onPressed: _goToCreate,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Novo administrador'),
                          ),
                        ),
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
                        FilledButton.icon(
                          onPressed: _goToCreate,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Novo administrador'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (controller.errorMessage != null)
            _ErrorBanner(message: controller.errorMessage!),
          Expanded(
            child: controller.loading
                ? const LoadingState(message: 'Carregando administradores...')
                : controller.items.isEmpty
                ? EmptyState(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Nenhum administrador encontrado',
                    message:
                        'Crie um novo usuário administrativo para iniciar a gestão.',
                    actionLabel: 'Novo administrador',
                    onAction: _goToCreate,
                  )
                : ListView.separated(
                    itemCount: controller.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final admin = controller.items[index];
                      final ativo = admin['is_active'] as bool? ?? true;
                      final nome = (admin['nome'] ?? '') as String;
                      final email = (admin['email'] ?? '') as String;
                      final createdAt = (admin['created_at'] ?? '') as String;

                      return _AdminCard(
                        nome: nome,
                        email: email,
                        createdAt: createdAt,
                        ativo: ativo,
                        onToggle: () async {
                          await controller.toggleStatus(admin['id'] as String);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ativo
                                    ? 'Administrador inativado.'
                                    : 'Administrador ativado.',
                              ),
                            ),
                          );
                        },
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
          child: Icon(Icons.admin_panel_settings_outlined, color: iconColor),
        ),
        const SizedBox(height: 16),
        Text(
          'Usuários administradores',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Gerencie contas administrativas com uma apresentação mais clara, consistente e institucional.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.45),
        ),
      ],
    );
  }
}

class _AdminCard extends StatefulWidget {
  final String nome;
  final String email;
  final String createdAt;
  final bool ativo;
  final VoidCallback onToggle;

  const _AdminCard({
    required this.nome,
    required this.email,
    required this.createdAt,
    required this.ativo,
    required this.onToggle,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        scale: hovering ? 1.01 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(
                          hovering ? 0.16 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          widget.nome.isNotEmpty
                              ? widget.nome[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nome.isEmpty ? 'Administrador' : widget.nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: widget.ativo ? 'Ativo' : 'Inativo',
                      color: widget.ativo
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const _DetailRow(label: 'Perfil', value: 'Administrador'),
                      const SizedBox(height: 10),
                      _DetailRow(
                        label: 'Criado em',
                        value: _formatDate(widget.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.info_outline_rounded),
                              label: const Text('Conta administrativa'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: widget.onToggle,
                              icon: Icon(
                                widget.ativo
                                    ? Icons.visibility_off_rounded
                                    : Icons.check_circle_rounded,
                              ),
                              label: Text(widget.ativo ? 'Inativar' : 'Ativar'),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.info_outline_rounded),
                            label: const Text('Conta administrativa'),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.tonalIcon(
                            onPressed: widget.onToggle,
                            icon: Icon(
                              widget.ativo
                                  ? Icons.visibility_off_rounded
                                  : Icons.check_circle_rounded,
                            ),
                            label: Text(widget.ativo ? 'Inativar' : 'Ativar'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
