import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';
import 'logs_controller.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late LogsController _controller;
  bool loading = true;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LogsController(authController);
    _loadData();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      await _controller.init();
      searchCtrl.text = _controller.search;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Logs',
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
                        const Expanded(child: _AuditInfoPanel()),
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
                        const _AuditInfoPanel(),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: (value) => setState(() {
                              _controller.setSearch(value);
                            }),
                            decoration: const InputDecoration(
                              labelText:
                                  'Buscar por ação, papel, entidade ou descrição',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _controller.actionFilter,
                            decoration: const InputDecoration(
                              labelText: 'Ação',
                              prefixIcon: Icon(Icons.filter_list_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'todas',
                                child: Text('Todas'),
                              ),
                              DropdownMenuItem(
                                value: 'create',
                                child: Text('Criações'),
                              ),
                              DropdownMenuItem(
                                value: 'update',
                                child: Text('Atualizações'),
                              ),
                              DropdownMenuItem(
                                value: 'delete',
                                child: Text('Exclusões'),
                              ),
                              DropdownMenuItem(
                                value: 'login',
                                child: Text('Logins'),
                              ),
                              DropdownMenuItem(
                                value: 'logout',
                                child: Text('Logouts'),
                              ),
                              DropdownMenuItem(
                                value: 'access',
                                child: Text('Acessos'),
                              ),
                              DropdownMenuItem(
                                value: 'approval',
                                child: Text('Aprovações'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(
                                  () => _controller.setActionFilter(value),
                                );
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
                          onChanged: (value) => setState(() {
                            _controller.setSearch(value);
                          }),
                          decoration: const InputDecoration(
                            labelText:
                                'Buscar por ação, papel, entidade ou descrição',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _controller.actionFilter,
                          decoration: const InputDecoration(
                            labelText: 'Ação',
                            prefixIcon: Icon(Icons.filter_list_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'todas',
                              child: Text('Todas'),
                            ),
                            DropdownMenuItem(
                              value: 'create',
                              child: Text('Criações'),
                            ),
                            DropdownMenuItem(
                              value: 'update',
                              child: Text('Atualizações'),
                            ),
                            DropdownMenuItem(
                              value: 'delete',
                              child: Text('Exclusões'),
                            ),
                            DropdownMenuItem(
                              value: 'login',
                              child: Text('Logins'),
                            ),
                            DropdownMenuItem(
                              value: 'logout',
                              child: Text('Logouts'),
                            ),
                            DropdownMenuItem(
                              value: 'access',
                              child: Text('Acessos'),
                            ),
                            DropdownMenuItem(
                              value: 'approval',
                              child: Text('Aprovações'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(
                                () => _controller.setActionFilter(value),
                              );
                            }
                          },
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const LoadingState(message: 'Carregando auditoria...')
                : _controller.items.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Sem logs',
                    message: 'Quando eventos ocorrerem, eles aparecerão aqui.',
                    actionLabel: 'Atualizar',
                    onAction: _loadData,
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.separated(
                      itemCount: _controller.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final log = _controller.items[i];
                        return _LogCard(
                          actionIcon: _getActionIcon(log.action),
                          actionColor: _getActionColor(log.action),
                          title: _getActionDescription(log),
                          subtitle:
                              '${log.actorRole ?? 'sistema'} • ${_formatDate(log.createdAt)}',
                          entityLabel: _getEntityDisplayName(log.entity),
                          onTap: () => _openDetails(log),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return Icons.add_circle_rounded;
      case AuditAction.update:
        return Icons.edit_rounded;
      case AuditAction.delete:
        return Icons.delete_rounded;
      case AuditAction.login:
        return Icons.login_rounded;
      case AuditAction.logout:
        return Icons.logout_rounded;
      case AuditAction.access:
        return Icons.visibility_rounded;
      case AuditAction.approval:
        return Icons.fact_check_rounded;
      case AuditAction.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getActionColor(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return const Color(0xFF15803D);
      case AuditAction.update:
        return const Color(0xFFD97706);
      case AuditAction.delete:
        return const Color(0xFFB91C1C);
      case AuditAction.login:
        return const Color(0xFF2563EB);
      case AuditAction.logout:
        return const Color(0xFF64748B);
      case AuditAction.access:
        return const Color(0xFF7C3AED);
      case AuditAction.approval:
        return const Color(0xFF0F766E);
      case AuditAction.other:
        return const Color(0xFF475569);
    }
  }

  String _getActionDescription(AuditLogModel log) {
    if ((log.description ?? '').trim().isNotEmpty) {
      return log.description!;
    }

    final entity = _getEntityDisplayName(log.entity);

    switch (log.action) {
      case AuditAction.create:
        return 'Criou $entity';
      case AuditAction.update:
        return 'Atualizou $entity';
      case AuditAction.delete:
        return 'Excluiu $entity';
      case AuditAction.login:
        return 'Login no sistema';
      case AuditAction.logout:
        return 'Logout do sistema';
      case AuditAction.access:
        return 'Acessou $entity';
      case AuditAction.approval:
        return 'Processou aprovação de $entity';
      case AuditAction.other:
        return log.rawAction.replaceAll('_', ' ');
    }
  }

  String _getEntityDisplayName(String entity) {
    switch (entity.toLowerCase()) {
      case 'profiles':
        return 'perfil';
      case 'pacientes':
        return 'paciente';
      case 'medicos':
        return 'médico';
      case 'tipos_procedimento':
        return 'tipo de procedimento';
      case 'procedimentos_realizados':
        return 'procedimento';
      case 'solicitacoes_imagem':
        return 'solicitação de imagem';
      case 'imagens_procedimento':
        return 'imagem do procedimento';
      case 'acessos_imagem_procedimento':
        return 'acesso à imagem';
      case 'audit_logs':
        return 'log';
      default:
        return entity;
    }
  }

  void _openDetails(AuditLogModel log) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActionDescription(log),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SoftBadge(
                    label: _labelForAction(log.action),
                    color: _getActionColor(log.action),
                  ),
                  _SoftBadge(
                    label: _getEntityDisplayName(log.entity),
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                color: const Color(0xFFF8FAFC),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Papel do ator',
                        value: log.actorRole ?? 'Sistema',
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        label: 'Data',
                        value: _formatFullDate(log.createdAt),
                      ),
                      if (log.entityId != null) ...[
                        const SizedBox(height: 10),
                        _DetailRow(label: 'ID técnico', value: log.entityId!),
                      ],
                      if ((log.rawAction).trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailRow(label: 'Ação bruta', value: log.rawAction),
                      ],
                    ],
                  ),
                ),
              ),
              if (log.metadata != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Metadados',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                _JsonBlock(content: _formatJson(log.metadata!)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _labelForAction(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return 'Criação';
      case AuditAction.update:
        return 'Atualização';
      case AuditAction.delete:
        return 'Exclusão';
      case AuditAction.login:
        return 'Login';
      case AuditAction.logout:
        return 'Logout';
      case AuditAction.access:
        return 'Acesso';
      case AuditAction.approval:
        return 'Aprovação';
      case AuditAction.other:
        return 'Outro';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatJson(Map<String, dynamic> json) {
    final filtered = Map<String, dynamic>.from(json)
      ..removeWhere((key, value) => value == null);

    return filtered.entries.map((e) => '${e.key}: ${e.value}').join('\n');
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
          child: Icon(Icons.receipt_long_outlined, color: iconColor),
        ),
        const SizedBox(height: 16),
        Text(
          'Auditoria do sistema',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Acompanhe eventos críticos, movimentações administrativas e histórico de ações registradas.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.45),
        ),
      ],
    );
  }
}

class _AuditInfoPanel extends StatelessWidget {
  const _AuditInfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          _SmallInfoItem(
            icon: Icons.visibility_outlined,
            title: 'Leitura mais clara',
            subtitle: 'Primeiro a ação, depois papel, data e detalhes.',
          ),
          SizedBox(height: 12),
          _SmallInfoItem(
            icon: Icons.security_rounded,
            title: 'Uso administrativo',
            subtitle:
                'Mais adequado para auditoria do que uma lista técnica crua.',
          ),
        ],
      ),
    );
  }
}

class _SmallInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SmallInfoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
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

class _LogCard extends StatefulWidget {
  final IconData actionIcon;
  final Color actionColor;
  final String title;
  final String subtitle;
  final String entityLabel;
  final VoidCallback onTap;

  const _LogCard({
    required this.actionIcon,
    required this.actionColor,
    required this.title,
    required this.subtitle,
    required this.entityLabel,
    required this.onTap,
  });

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
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
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.actionColor.withOpacity(
                        hovering ? 0.16 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.actionIcon, color: widget.actionColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SoftBadge(
                              label: widget.entityLabel,
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SoftBadge({required this.label, required this.color});

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

class _JsonBlock extends StatelessWidget {
  final String content;

  const _JsonBlock({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF4)),
      ),
      child: SelectableText(
        content.trim().isEmpty ? 'Sem conteúdo relevante.' : content,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
