import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';
import 'paciente_model.dart';
import 'pacientes_controller.dart';

class PacientesListScreen extends StatefulWidget {
  const PacientesListScreen({super.key});

  @override
  State<PacientesListScreen> createState() => _PacientesListScreenState();
}

class _PacientesListScreenState extends State<PacientesListScreen> {
  final controller = PacientesController();
  final searchCtrl = TextEditingController();

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
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToCreate() async {
    await context.push('/pacientes/novo', extra: controller);

    if (!mounted) return;
    await controller.init();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista de pacientes atualizada.')),
    );
  }

  Future<void> _goToEdit(PacienteModel paciente) async {
    await context.push('/pacientes/editar/${paciente.id}', extra: controller);

    if (!mounted) return;
    await controller.init();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paciente atualizado.')));
  }

  Future<void> _togglePaciente(PacienteModel paciente) async {
    await controller.toggle(paciente.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paciente.ativo ? 'Paciente inativado.' : 'Paciente ativado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 820;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Pacientes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactHeaderCard(
            title: 'Gestão de pacientes',
            subtitle:
                'Cadastre, filtre e mantenha pacientes com menos ruído visual e leitura mais objetiva.',
            icon: Icons.people_outline_rounded,
            iconColor: scheme.primary,
            iconBackground: scheme.primary.withOpacity(0.10),
            trailing: SizedBox(
              width: isWide ? 190 : double.infinity,
              child: FilledButton.icon(
                onPressed: _goToCreate,
                icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
                label: const Text('Novo paciente'),
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
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: controller.setSearch,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              labelText: 'Buscar por nome, e-mail ou telefone',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: controller.status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.filter_list_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'ativos',
                                child: Text('Somente ativos'),
                              ),
                              DropdownMenuItem(
                                value: 'inativos',
                                child: Text('Somente inativos'),
                              ),
                              DropdownMenuItem(
                                value: 'todos',
                                child: Text('Todos'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) controller.setStatus(value);
                            },
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: searchCtrl,
                          onChanged: controller.setSearch,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            labelText: 'Buscar por nome, e-mail ou telefone',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: controller.status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.filter_list_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ativos',
                              child: Text('Somente ativos'),
                            ),
                            DropdownMenuItem(
                              value: 'inativos',
                              child: Text('Somente inativos'),
                            ),
                            DropdownMenuItem(
                              value: 'todos',
                              child: Text('Todos'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) controller.setStatus(value);
                          },
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (controller.errorMessage != null)
            _ErrorBanner(message: controller.errorMessage!),
          Expanded(
            child: controller.loading
                ? const LoadingState(message: 'Carregando pacientes...')
                : controller.items.isEmpty
                ? EmptyState(
                    icon: Icons.people_rounded,
                    title: 'Nenhum paciente encontrado',
                    message: 'Cadastre um paciente ou ajuste os filtros.',
                    actionLabel: 'Novo paciente',
                    onAction: _goToCreate,
                  )
                : ListView.separated(
                    itemCount: controller.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final paciente = controller.items[i];
                      return _PacienteCard(
                        paciente: paciente,
                        onEdit: () => _goToEdit(paciente),
                        onToggleStatus: () => _togglePaciente(paciente),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PacienteCard extends StatefulWidget {
  final PacienteModel paciente;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _PacienteCard({
    required this.paciente,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  State<_PacienteCard> createState() => _PacienteCardState();
}

class _PacienteCardState extends State<_PacienteCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final paciente = widget.paciente;
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 760;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        scale: hovering ? 1.01 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: widget.onEdit,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(
                            hovering ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            paciente.nome.isNotEmpty
                                ? paciente.nome[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: AppIconSize.md,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paciente.nome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              paciente.email,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        label: paciente.ativo ? 'Ativo' : 'Inativo',
                        color: paciente.ativo
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Column(children: []),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xxs),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Telefone', valueFallback: '-'),
                        Builder(
                          builder: (context) => _InfoRow(
                            label: 'Telefone',
                            value: paciente.telefone.isEmpty
                                ? '-'
                                : paciente.telefone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onEdit,
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: const Text('Editar'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: widget.onToggleStatus,
                                icon: Icon(
                                  paciente.ativo
                                      ? Icons.visibility_off_rounded
                                      : Icons.check_circle_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: Text(
                                  paciente.ativo ? 'Inativar' : 'Ativar',
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.onEdit,
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: const Text('Editar'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: widget.onToggleStatus,
                                icon: Icon(
                                  paciente.ativo
                                      ? Icons.visibility_off_rounded
                                      : Icons.check_circle_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: Text(
                                  paciente.ativo ? 'Inativar' : 'Ativar',
                                ),
                              ),
                            ),
                          ],
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

class _CompactHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget trailing;

  const _CompactHeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: iconColor, size: AppIconSize.md),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _HeaderTexts(title: title, subtitle: subtitle),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  trailing,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: iconColor, size: AppIconSize.md),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _HeaderTexts(title: title, subtitle: subtitle),
                  const SizedBox(height: AppSpacing.sm),
                  trailing,
                ],
              ),
      ),
    );
  }
}

class _HeaderTexts extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderTexts({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

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

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? valueFallback;

  const _InfoRow({required this.label, this.value, this.valueFallback});

  @override
  Widget build(BuildContext context) {
    final finalValue = value ?? valueFallback ?? '-';

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
            finalValue,
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppRadius.md),
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
