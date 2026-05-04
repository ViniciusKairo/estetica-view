import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';
import 'medico_model.dart';
import 'medicos_controller.dart';

class MedicosListScreen extends StatefulWidget {
  const MedicosListScreen({super.key});

  @override
  State<MedicosListScreen> createState() => _MedicosListScreenState();
}

class _MedicosListScreenState extends State<MedicosListScreen> {
  final controller = MedicosController();
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
    await context.push('/medicos/novo', extra: controller);
    if (mounted) await controller.init();
  }

  Future<void> _goToEdit(MedicoModel medico) async {
    await context.push('/medicos/editar/${medico.id}', extra: controller);
    if (mounted) await controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 820;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Médicos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactHeaderCard(
            title: 'Gestão de médicos',
            subtitle:
                'Cadastre, edite e controle profissionais com leitura mais clara e menos peso visual.',
            icon: Icons.medical_services_outlined,
            iconColor: scheme.primary,
            iconBackground: scheme.primary.withOpacity(0.10),
            trailing: SizedBox(
              width: isWide ? 180 : double.infinity,
              child: FilledButton.icon(
                onPressed: _goToCreate,
                icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
                label: const Text('Novo médico'),
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
                              labelText:
                                  'Buscar por nome, e-mail, CRM ou especialização',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: controller.statusFilter,
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
                              if (value != null) {
                                controller.setStatusFilter(value);
                              }
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
                            labelText:
                                'Buscar por nome, e-mail, CRM ou especialização',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: controller.statusFilter,
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
                            if (value != null) {
                              controller.setStatusFilter(value);
                            }
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
                ? const LoadingState(message: 'Carregando médicos...')
                : controller.items.isEmpty
                ? EmptyState(
                    icon: Icons.medical_services_rounded,
                    title: 'Nenhum médico encontrado',
                    message: 'Cadastre um médico ou ajuste os filtros.',
                    actionLabel: 'Novo médico',
                    onAction: _goToCreate,
                  )
                : ListView.separated(
                    itemCount: controller.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) {
                      final medico = controller.items[index];
                      return _MedicoCard(
                        medico: medico,
                        onEdit: () => _goToEdit(medico),
                        onToggleStatus: () async {
                          await controller.toggleStatus(medico.id);
                          if (!mounted) return;
                          final status = medico.ativo ? 'inativado' : 'ativado';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Médico $status com sucesso.'),
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

class _MedicoCard extends StatefulWidget {
  final MedicoModel medico;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _MedicoCard({
    required this.medico,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  State<_MedicoCard> createState() => _MedicoCardState();
}

class _MedicoCardState extends State<_MedicoCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final medico = widget.medico;
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
                        child: Icon(
                          Icons.medical_services_rounded,
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
                              medico.nome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              medico.email,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        label: medico.ativo ? 'Ativo' : 'Inativo',
                        color: medico.ativo
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
                    child: Column(
                      children: [
                        _InfoRow(label: 'CRM', value: medico.crm),
                        const SizedBox(height: AppSpacing.xs),
                        _InfoRow(
                          label: 'Especialização',
                          value: medico.especializacao.isEmpty
                              ? '-'
                              : medico.especializacao,
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
                                  medico.ativo
                                      ? Icons.visibility_off_rounded
                                      : Icons.check_circle_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: Text(
                                  medico.ativo ? 'Inativar' : 'Ativar',
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
                                  medico.ativo
                                      ? Icons.visibility_off_rounded
                                      : Icons.check_circle_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: Text(
                                  medico.ativo ? 'Inativar' : 'Ativar',
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
  final String value;

  const _InfoRow({required this.label, required this.value});

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
