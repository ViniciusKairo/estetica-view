import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';
import 'solicitacao_imagem_model.dart';
import 'solicitacoes_imagens_controller.dart';

class SolicitacoesImagensListScreen extends StatefulWidget {
  const SolicitacoesImagensListScreen({super.key});

  @override
  State<SolicitacoesImagensListScreen> createState() =>
      _SolicitacoesImagensListScreenState();
}

class _SolicitacoesImagensListScreenState
    extends State<SolicitacoesImagensListScreen> {
  late final SolicitacoesImagensController controller;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = SolicitacoesImagensController();
    controller.addListener(_onControllerChanged);
    controller.init();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await controller.init();
  }

  Future<void> _approve(SolicitacaoImagemModel item) async {
    try {
      await controller.approve(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação aprovada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao aprovar: $e')));
    }
  }

  Future<void> _reject(SolicitacaoImagemModel item) async {
    final motivoCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reprovar solicitação'),
          content: TextField(
            controller: motivoCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo da reprovação (opcional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reprovar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      motivoCtrl.dispose();
      return;
    }

    try {
      await controller.reject(
        item.id,
        motivo: motivoCtrl.text.trim().isEmpty ? null : motivoCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação reprovada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao reprovar: $e')));
    } finally {
      motivoCtrl.dispose();
    }
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final items = controller.items;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Aprovações',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactHeaderCard(
            icon: Icons.fact_check_rounded,
            title: 'Aprovações',
            subtitle:
                'Analise os pedidos de acesso às imagens com menos ruído visual e mais foco nas ações.',
            iconColor: scheme.primary,
            iconBackground: scheme.primary.withOpacity(0.10),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: controller.setSearch,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por paciente, tipo ou ID',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: controller.statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filtro por status',
                      prefixIcon: Icon(Icons.filter_list_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'todas', child: Text('Todas')),
                      DropdownMenuItem(
                        value: 'pendentes',
                        child: Text('Pendentes'),
                      ),
                      DropdownMenuItem(
                        value: 'aprovadas',
                        child: Text('Aprovadas'),
                      ),
                      DropdownMenuItem(
                        value: 'reprovadas',
                        child: Text('Reprovadas'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      controller.setStatusFilter(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: controller.loading
                ? const LoadingState(message: 'Carregando aprovações...')
                : items.isEmpty
                ? EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Nenhuma solicitação encontrada',
                    message:
                        controller.search.trim().isNotEmpty ||
                            controller.statusFilter != 'todas'
                        ? 'A busca ou o filtro não retornaram resultados.'
                        : 'Ainda não há solicitações registradas.',
                    actionLabel: 'Recarregar',
                    onAction: _reload,
                  )
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isPending =
                            item.status == SolicitacaoStatus.pendente;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.tipoNome,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _InfoLine(
                                  label: 'Paciente',
                                  value: item.pacienteNome,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _InfoLine(
                                  label: 'Criada em',
                                  value: _formatDate(item.criadaEm),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _InfoLine(
                                  label: 'Status',
                                  value: _statusLabel(item.status),
                                ),
                                if ((item.observacao ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  _InfoLine(
                                    label: 'Observação',
                                    value: item.observacao!,
                                  ),
                                ],
                                if ((item.motivoReprovacao ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  _InfoLine(
                                    label: 'Motivo',
                                    value: item.motivoReprovacao!,
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                if (isPending)
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: () => _approve(item),
                                        icon: const Icon(
                                          Icons.check_rounded,
                                          size: AppIconSize.sm,
                                        ),
                                        label: const Text('Aprovar'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _reject(item),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: AppIconSize.sm,
                                        ),
                                        label: const Text('Reprovar'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactHeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;

  const _CompactHeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Color(0xFF0F172A))),
        ),
      ],
    );
  }
}

String _statusLabel(SolicitacaoStatus status) {
  switch (status) {
    case SolicitacaoStatus.pendente:
      return 'Pendente';
    case SolicitacaoStatus.aprovada:
      return 'Aprovada';
    case SolicitacaoStatus.reprovada:
      return 'Reprovada';
  }
}
