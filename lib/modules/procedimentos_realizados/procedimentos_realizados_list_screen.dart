import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';
import 'procedimento_realizado_model.dart';
import 'procedimentos_realizados_controller.dart';

class ProcedimentosRealizadosListScreen extends StatefulWidget {
  const ProcedimentosRealizadosListScreen({super.key});

  @override
  State<ProcedimentosRealizadosListScreen> createState() =>
      _ProcedimentosRealizadosListScreenState();
}

class _ProcedimentosRealizadosListScreenState
    extends State<ProcedimentosRealizadosListScreen> {
  final controller = ProcedimentosRealizadosController();
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
    await context.push('/procedimentos-realizados/novo', extra: controller);
    if (mounted) setState(() {});
  }

  Future<void> _goToEdit(ProcedimentoRealizadoModel item) async {
    await context.push(
      '/procedimentos-realizados/editar/${item.id}',
      extra: controller,
    );
    if (mounted) setState(() {});
  }

  Future<void> _goToImages(ProcedimentoRealizadoModel item) async {
    await context.push(
      '/procedimentos-realizados/${item.id}/imagens',
      extra: {'procedureName': item.tipoNome},
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleRelease(
    ProcedimentoRealizadoModel item,
    bool value,
  ) async {
    try {
      await controller.setImagesReleasedToPatient(
        procedureId: item.id,
        released: value,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Imagens liberadas para o paciente.'
                : 'Acesso do paciente revogado.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar liberação: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 840;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Procedimentos realizados',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactHeaderCard(
            title: 'Registro de procedimentos',
            subtitle:
                'Acompanhe procedimentos realizados e controle a disponibilidade das imagens com leitura mais clara.',
            icon: Icons.assignment_outlined,
            iconColor: scheme.primary,
            iconBackground: scheme.primary.withOpacity(0.10),
            trailing: SizedBox(
              width: isWide ? 220 : double.infinity,
              child: FilledButton.icon(
                onPressed: _goToCreate,
                icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
                label: const Text('Novo procedimento'),
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
                              labelText: 'Buscar por paciente ou tipo',
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
                                child: Text('Ativos'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelados',
                                child: Text('Cancelados'),
                              ),
                              DropdownMenuItem(
                                value: 'todos',
                                child: Text('Todos'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) controller.setStatusFilter(v);
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
                            labelText: 'Buscar por paciente ou tipo',
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
                              child: Text('Ativos'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelados',
                              child: Text('Cancelados'),
                            ),
                            DropdownMenuItem(
                              value: 'todos',
                              child: Text('Todos'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) controller.setStatusFilter(v);
                          },
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: controller.loading
                ? const LoadingState(message: 'Carregando procedimentos...')
                : controller.items.isEmpty
                ? EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Nenhum procedimento encontrado',
                    message:
                        'Cadastre um procedimento realizado para iniciar o controle clínico.',
                    actionLabel: 'Novo procedimento',
                    onAction: _goToCreate,
                  )
                : ListView.separated(
                    itemCount: controller.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final item = controller.items[i];
                      return _ProcedimentoCard(
                        item: item,
                        busy: controller.updatingRelease,
                        onEdit: () => _goToEdit(item),
                        onViewImages: () => _goToImages(item),
                        onToggleRelease: (value) => _toggleRelease(item, value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProcedimentoCard extends StatefulWidget {
  final ProcedimentoRealizadoModel item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onViewImages;
  final ValueChanged<bool> onToggleRelease;

  const _ProcedimentoCard({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onViewImages,
    required this.onToggleRelease,
  });

  @override
  State<_ProcedimentoCard> createState() => _ProcedimentoCardState();
}

class _ProcedimentoCardState extends State<_ProcedimentoCard> {
  bool hovering = false;

  String _statusText() {
    switch (widget.item.status) {
      case ProcedimentoStatus.pendenteImagens:
        return 'Pendente imagens';
      case ProcedimentoStatus.emAndamento:
        return 'Em andamento';
      case ProcedimentoStatus.concluido:
        return 'Concluído';
      case ProcedimentoStatus.cancelado:
        return 'Cancelado';
    }
  }

  Color _statusColor() {
    switch (widget.item.status) {
      case ProcedimentoStatus.pendenteImagens:
        return const Color(0xFFD97706);
      case ProcedimentoStatus.emAndamento:
        return const Color(0xFF2563EB);
      case ProcedimentoStatus.concluido:
        return const Color(0xFF15803D);
      case ProcedimentoStatus.cancelado:
        return const Color(0xFFB91C1C);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = _statusColor();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: widget.onViewImages,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icons.assignment_outlined,
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
                              item.tipoNome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Paciente: ${item.pacienteNome}',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(label: _statusText(), color: statusColor),
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
                        _InfoRow(label: 'Médico', value: item.medicoNome),
                        const SizedBox(height: AppSpacing.xs),
                        _InfoRow(
                          label: 'Data',
                          value: _formatDate(item.dataRealizacao),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _InfoRow(
                          label: 'Acesso do paciente',
                          value: item.imagesReleasedToPatient
                              ? 'Liberado'
                              : 'Bloqueado',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Liberar imagens para o paciente',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      item.imagesReleasedToPatient
                          ? 'O paciente já pode visualizar as imagens deste procedimento.'
                          : 'O paciente ainda não pode visualizar as imagens deste procedimento.',
                    ),
                    value: item.imagesReleasedToPatient,
                    onChanged: widget.busy ? null : widget.onToggleRelease,
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
                                onPressed: widget.onViewImages,
                                icon: const Icon(
                                  Icons.photo_library_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: const Text('Abrir imagens'),
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
                                onPressed: widget.onViewImages,
                                icon: const Icon(
                                  Icons.photo_library_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: const Text('Abrir imagens'),
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
