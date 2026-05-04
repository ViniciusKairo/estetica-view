import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/app_scaffold.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/loading_state.dart';

class _PacienteProcedimentoLiberado {
  final String id;
  final String tipoNome;
  final String medicoNome;
  final DateTime dataRealizacao;

  const _PacienteProcedimentoLiberado({
    required this.id,
    required this.tipoNome,
    required this.medicoNome,
    required this.dataRealizacao,
  });
}

class PacienteProcedimentosScreen extends StatefulWidget {
  const PacienteProcedimentosScreen({super.key});

  @override
  State<PacienteProcedimentosScreen> createState() =>
      _PacienteProcedimentosScreenState();
}

class _PacienteProcedimentosScreenState
    extends State<PacienteProcedimentosScreen> {
  final _client = Supabase.instance.client;

  bool loading = true;
  String? errorMessage;
  List<_PacienteProcedimentoLiberado> procedures = [];

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
            acessos_imagem_procedimento!inner(
              is_active,
              paciente_id
            )
          ''')
          .eq('paciente_id', pacienteId)
          .eq('acessos_imagem_procedimento.paciente_id', pacienteId)
          .eq('acessos_imagem_procedimento.is_active', true)
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

            final data = DateTime.tryParse(
              row['data_procedimento']?.toString() ?? '',
            );

            if (data == null) return null;

            return _PacienteProcedimentoLiberado(
              id: row['id']?.toString() ?? '',
              tipoNome: tipo['nome']?.toString() ?? 'Procedimento',
              medicoNome:
                  medicoProfile['nome']?.toString() ?? 'Médico não informado',
              dataRealizacao: data,
            );
          })
          .whereType<_PacienteProcedimentoLiberado>()
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

  void _openImages(_PacienteProcedimentoLiberado item) {
    context.push(
      '/procedimentos-realizados/${item.id}/imagens',
      extra: {'procedureName': item.tipoNome},
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Meus procedimentos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image_rounded, color: Color(0xFF2563EB)),
                      SizedBox(width: 12),
                      Text(
                        'Meus Procedimentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aqui aparecem apenas procedimentos com imagens já liberadas para sua visualização.',
                    style: TextStyle(color: Color(0xFF64748B), height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
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
                    icon: Icons.photo_library_outlined,
                    title: 'Nenhum procedimento liberado',
                    message:
                        'Quando a clínica liberar as imagens de um procedimento, ele aparecerá aqui para visualização.',
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: procedures.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final item = procedures[i];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openImages(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.photo_library_rounded,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.tipoNome,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text('Médico: ${item.medicoNome}'),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Concluído em: ${_formatDate(item.dataRealizacao)}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.tonal(
                                      onPressed: () => _openImages(item),
                                      child: const Text('Ver imagens'),
                                    ),
                                  ),
                                ],
                              ),
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
