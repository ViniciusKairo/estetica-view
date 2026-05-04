import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';
import 'tipos_procedimento_controller.dart';
import 'tipo_procedimento_model.dart';

class TiposProcedimentoListScreen extends StatefulWidget {
  const TiposProcedimentoListScreen({super.key});

  @override
  State<TiposProcedimentoListScreen> createState() =>
      _TiposProcedimentoListScreenState();
}

class _TiposProcedimentoListScreenState
    extends State<TiposProcedimentoListScreen> {
  final controller = TiposProcedimentoController();
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
    await context.push('/tipos-procedimento/novo', extra: controller);
    if (mounted) await controller.init();
  }

  Future<void> _goToEdit(TipoProcedimentoModel tipo) async {
    await context.push(
      '/tipos-procedimento/editar/${tipo.id}',
      extra: controller,
    );
    if (mounted) await controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 820;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Tipos de Procedimento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactHeaderCard(
            title: 'Catálogo de procedimentos',
            subtitle:
                'Cadastre e mantenha os tipos disponíveis com leitura mais limpa e menos peso visual.',
            icon: Icons.category_outlined,
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
                              prefixIcon: Icon(Icons.search_rounded),
                              labelText: 'Buscar procedimento',
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
                            labelText: 'Buscar procedimento',
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
          Expanded(
            child: controller.loading
                ? const LoadingState(message: 'Carregando tipos...')
                : controller.items.isEmpty
                ? EmptyState(
                    icon: Icons.medical_services_rounded,
                    title: 'Nenhum procedimento',
                    message: 'Cadastre um tipo para começar.',
                    actionLabel: 'Novo procedimento',
                    onAction: _goToCreate,
                  )
                : ListView.separated(
                    itemCount: controller.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final tipo = controller.items[i];

                      return _TipoCard(
                        tipo: tipo,
                        onEdit: () => _goToEdit(tipo),
                        onToggle: () async {
                          await controller.toggle(tipo.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Status atualizado.')),
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

class _TipoCard extends StatefulWidget {
  final TipoProcedimentoModel tipo;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _TipoCard({
    required this.tipo,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_TipoCard> createState() => _TipoCardState();
}

class _TipoCardState extends State<_TipoCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final tipo = widget.tipo;
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
                        width: 54,
                        height: 54,
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
                              tipo.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              tipo.descricao.isEmpty
                                  ? 'Sem descrição'
                                  : tipo.descricao,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        label: tipo.ativo ? 'Ativo' : 'Inativo',
                        color: tipo.ativo
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C),
                      ),
                    ],
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
                                onPressed: widget.onToggle,
                                icon: Icon(
                                  tipo.ativo
                                      ? Icons.visibility_off_rounded
                                      : Icons.check_circle_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: Text(tipo.ativo ? 'Inativar' : 'Ativar'),
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
                                onPressed: widget.onToggle,
                                icon: Icon(
                                  tipo.ativo
                                      ? Icons.visibility_off_rounded
                                      : Icons.check_circle_rounded,
                                  size: AppIconSize.sm,
                                ),
                                label: Text(tipo.ativo ? 'Inativar' : 'Ativar'),
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
