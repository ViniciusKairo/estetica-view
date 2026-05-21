import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';

class _PacienteProcedureItem {
  final String id;
  final String tipoNome;
  final String medicoNome;
  final DateTime? dataRealizacao;
  final String? requestStatus;

  const _PacienteProcedureItem({
    required this.id,
    required this.tipoNome,
    required this.medicoNome,
    required this.dataRealizacao,
    this.requestStatus,
  });
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _client = Supabase.instance.client;

  bool loading = true;
  String? errorMessage;
  List<_PacienteProcedureItem> procedures = [];

  @override
  void initState() {
    super.initState();
    _loadProcedures();
  }

  Future<void> _loadProcedures() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      final pacienteRow = await _client
          .from('pacientes')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (pacienteRow == null) {
        throw Exception('Paciente não encontrado para o usuário logado.');
      }

      final pacienteId = pacienteRow['id']?.toString();
      if (pacienteId == null || pacienteId.isEmpty) {
        throw Exception('ID do paciente não encontrado.');
      }

      final response = await _client
          .from('procedimentos_realizados')
          .select('''
            id,
            data_procedimento,
            medicos!medico_id(
            profiles(nome)
            ),
            tipos_procedimento!tipo_procedimento_id(nome),
            solicitacoes_imagem(status, requested_at),
            acessos_imagem_procedimento(is_active, granted_at, revoked_at)
          ''')
          .eq('paciente_id', pacienteId)
          .order('data_procedimento', ascending: false);

      final loaded = (response as List)
          .map((item) {
            final row = Map<String, dynamic>.from(item as Map);

            final medico = row['medicos'] is Map<String, dynamic>
                ? row['medicos'] as Map<String, dynamic>
                : row['medicos'] is Map
                ? Map<String, dynamic>.from(row['medicos'] as Map)
                : <String, dynamic>{};

            final medicoProfile = medico['profiles'] is Map<String, dynamic>
                ? medico['profiles'] as Map<String, dynamic>
                : medico['profiles'] is Map
                ? Map<String, dynamic>.from(medico['profiles'] as Map)
                : <String, dynamic>{};

            final tipo = row['tipos_procedimento'] is Map<String, dynamic>
                ? row['tipos_procedimento'] as Map<String, dynamic>
                : row['tipos_procedimento'] is Map
                ? Map<String, dynamic>.from(row['tipos_procedimento'] as Map)
                : <String, dynamic>{};

            final requestsRaw = row['solicitacoes_imagem'];
            final requests = requestsRaw is List
                ? requestsRaw
                      .map((r) => Map<String, dynamic>.from(r as Map))
                      .toList()
                : <Map<String, dynamic>>[];

            requests.sort((a, b) {
              final aDate =
                  DateTime.tryParse(a['requested_at']?.toString() ?? '') ??
                  DateTime(2000);
              final bDate =
                  DateTime.tryParse(b['requested_at']?.toString() ?? '') ??
                  DateTime(2000);
              return bDate.compareTo(aDate);
            });

            final latestStatus = requests.isNotEmpty
                ? requests.first['status']?.toString()
                : null;

            return _PacienteProcedureItem(
              id: row['id']?.toString() ?? '',
              tipoNome: tipo['nome']?.toString() ?? 'Procedimento',
              medicoNome:
                  medicoProfile['nome']?.toString() ?? 'Médico não informado',
              dataRealizacao: DateTime.tryParse(
                row['data_procedimento']?.toString() ?? '',
              ),
              requestStatus: latestStatus,
            );
          })
          .where((e) => e.id.isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        procedures = loaded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        procedures = [];
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadProcedures();
  }

  Future<void> _openForm(String procedureId) async {
    await context.push(
      '/solicitacoes-imagens/novo',
      extra: {'procId': procedureId},
    );

    if (!mounted) return;
    await _loadProcedures();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Data não informada';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  bool _hasActiveRequest(String? status) {
    // 'reprovada' allows the patient to submit a new request
    return status == 'pendente' || status == 'aprovada';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pendente':
        return 'Solicitação pendente';
      case 'aprovada':
        return 'Imagens liberadas';
      case 'reprovada':
        return 'Solicitação reprovada';
      default:
        return 'Sem solicitação ativa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Solicitar acesso às imagens',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Selecione um procedimento e envie a solicitação de acesso às imagens.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: loading
                ? const LoadingState(message: 'Carregando procedimentos...')
                : errorMessage != null
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'Falha ao carregar',
                    message: errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: _loadProcedures,
                  )
                : procedures.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Nenhum procedimento encontrado',
                    message:
                        'Você não possui procedimentos vinculados para solicitar imagens.',
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: procedures.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = procedures[index];
                        final blocked = _hasActiveRequest(item.requestStatus);

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.tipoNome,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  label: 'Médico',
                                  value: item.medicoNome,
                                ),
                                const SizedBox(height: 4),
                                _InfoRow(
                                  label: 'Data',
                                  value: _formatDate(item.dataRealizacao),
                                ),
                                const SizedBox(height: 4),
                                _InfoRow(
                                  label: 'Status',
                                  value: _statusLabel(item.requestStatus),
                                ),
                                if (item.requestStatus == 'reprovada') ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sua solicitação foi recusada. Você pode solicitar novamente.',
                                    style: TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: blocked
                                        ? null
                                        : () => _openForm(item.id),
                                    child: Text(
                                      blocked
                                          ? 'Solicitação já existente'
                                          : 'Solicitar acesso',
                                    ),
                                  ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
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
