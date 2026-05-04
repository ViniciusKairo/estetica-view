import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/app_scaffold.dart';
import '../../ui/widgets/form_actions_bar.dart';
import '../../ui/widgets/form_page_shell.dart';
import '../../ui/widgets/form_section_card.dart';
import '../../ui/widgets/loading_state.dart';

class SolicitacaoImagemFormScreen extends StatefulWidget {
  final String? procedimentoRealizadoId;

  const SolicitacaoImagemFormScreen({super.key, this.procedimentoRealizadoId});

  @override
  State<SolicitacaoImagemFormScreen> createState() =>
      _SolicitacaoImagemFormScreenState();
}

class _SolicitacaoImagemFormScreenState
    extends State<SolicitacaoImagemFormScreen> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _observacaoController = TextEditingController();

  bool loading = true;
  bool saving = false;

  String? _procedureId;
  String _tipoNome = 'Procedimento';
  String _medicoNome = 'Médico não informado';
  DateTime? _dataRealizacao;
  bool _imagesReleasedToPatient = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final procId = widget.procedimentoRealizadoId;
      if (procId == null || procId.isEmpty) {
        throw Exception('Procedimento não informado.');
      }

      _procedureId = procId;
      await _loadProcedureDetails(procId);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _loadProcedureDetails(String procedureId) async {
    final row = await _client
        .from('procedimentos_realizados')
        .select('''
          id,
          data_procedimento,
          medicos!medico_id(
            profiles(nome)
          ),
          tipos_procedimento!tipo_procedimento_id(nome),
          acessos_imagem_procedimento!left(is_active)
        ''')
        .eq('id', procedureId)
        .maybeSingle();

    if (row == null) {
      throw Exception('Procedimento não encontrado.');
    }

    final map = Map<String, dynamic>.from(row as Map);

    final tipo = map['tipos_procedimento'] is Map<String, dynamic>
        ? map['tipos_procedimento'] as Map<String, dynamic>
        : map['tipos_procedimento'] is Map
        ? Map<String, dynamic>.from(map['tipos_procedimento'] as Map)
        : <String, dynamic>{};

    final medico = map['medicos'] is Map<String, dynamic>
        ? map['medicos'] as Map<String, dynamic>
        : map['medicos'] is Map
        ? Map<String, dynamic>.from(map['medicos'] as Map)
        : <String, dynamic>{};

    final medicoProfile = medico['profiles'] is Map<String, dynamic>
        ? medico['profiles'] as Map<String, dynamic>
        : medico['profiles'] is Map
        ? Map<String, dynamic>.from(medico['profiles'] as Map)
        : <String, dynamic>{};

    _tipoNome = tipo['nome']?.toString() ?? 'Procedimento';
    _medicoNome = medicoProfile['nome']?.toString() ?? 'Médico não informado';
    _dataRealizacao = DateTime.tryParse(
      map['data_procedimento']?.toString() ?? '',
    );

    final acessos = map['acessos_imagem_procedimento'] as List?;
    _imagesReleasedToPatient =
        (acessos?.any((a) => (a as Map)['is_active'] == true)) ?? false;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (_procedureId == null || _procedureId!.isEmpty) {
      _showMessage('Procedimento não informado.');
      return;
    }

    setState(() {
      saving = true;
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

      final procRow = await _client
          .from('procedimentos_realizados')
          .select('paciente_id')
          .eq('id', _procedureId!)
          .maybeSingle();

      if (procRow == null) {
        throw Exception('Procedimento não encontrado.');
      }

      if ((procRow['paciente_id']?.toString() ?? '') != pacienteId) {
        throw Exception('Este procedimento não pertence ao paciente logado.');
      }

      final existing = await _client
          .from('solicitacoes_imagem')
          .select('id, status')
          .eq('procedimento_id', _procedureId!)
          .eq('paciente_id', pacienteId)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        final status = (existing['status'] ?? '').toString();

        final hasActiveRequest = status == 'pendente' || status == 'aprovada';

        if (hasActiveRequest) {
          throw Exception(
            'Já existe uma solicitação ativa para este procedimento.',
          );
        }
      }

      await _client.from('solicitacoes_imagem').insert({
        'procedimento_id': _procedureId,
        'paciente_id': pacienteId,
        'status': 'pendente',
        'observacao': _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
      });

      if (!mounted) return;

      _showMessage('Solicitação enviada com sucesso.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() {
        saving = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Data não informada';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildProcedureInfo() {
    return FormSectionCard(
      title: 'Procedimento',
      subtitle: 'Confirme os dados antes de enviar a solicitação.',
      icon: Icons.medical_information_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tipo: $_tipoNome'),
          const SizedBox(height: 8),
          Text('Médico: $_medicoNome'),
          const SizedBox(height: 8),
          Text('Data: ${_formatDate(_dataRealizacao)}'),
          if (_imagesReleasedToPatient) ...[
            const SizedBox(height: 12),
            const Text(
              'As imagens deste procedimento já foram liberadas ao paciente.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return FormSectionCard(
      title: 'Solicitação',
      subtitle: 'Adicione uma observação apenas se necessário.',
      icon: Icons.assignment_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _observacaoController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nova solicitação de imagens',
      showBack: true,
      child: loading
          ? const LoadingState(message: 'Carregando dados...')
          : Form(
              key: _formKey,
              child: FormPageShell(
                title: 'Solicitação de imagens',
                subtitle:
                    'Tela simplificada para reduzir erro e focar no fluxo.',
                icon: Icons.assignment_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProcedureInfo(),
                    const SizedBox(height: 16),
                    _buildFormFields(),
                    const SizedBox(height: 16),
                    FormActionsBar(
                      primaryLabel: 'Enviar',
                      onPrimary: saving ? null : _save,
                      secondaryLabel: 'Cancelar',
                      onSecondary: saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      loading: saving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
