import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/form_actions_bar.dart';
import '../../ui/widgets/form_page_shell.dart';
import '../../ui/widgets/form_section_card.dart';
import 'procedimentos_realizados_controller.dart';
import 'procedimento_realizado_model.dart';

class ProcedimentoRealizadoFormScreen extends StatefulWidget {
  final ProcedimentosRealizadosController controller;
  final String? recordId;

  const ProcedimentoRealizadoFormScreen({
    super.key,
    required this.controller,
    this.recordId,
  });

  @override
  State<ProcedimentoRealizadoFormScreen> createState() =>
      _ProcedimentoRealizadoFormScreenState();
}

class _ProcedimentoRealizadoFormScreenState
    extends State<ProcedimentoRealizadoFormScreen> {
  final formKey = GlobalKey<FormState>();

  String? pacienteId;
  String? medicoId;
  String? tipoId;

  DateTime data = DateTime.now();
  ProcedimentoStatus status = ProcedimentoStatus.pendenteImagens;

  final obsCtrl = TextEditingController();
  bool saving = false;

  bool get isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final item = widget.controller.findById(widget.recordId!);
      if (item != null) {
        pacienteId = item.pacienteId;
        medicoId = item.medicoId;
        tipoId = item.tipoId;
        data = item.dataRealizacao;
        status = item.status;
        obsCtrl.text = item.observacoes ?? '';
      }
    } else {
      pacienteId = widget.controller.pacientes.isNotEmpty
          ? widget.controller.pacientes.first.id
          : null;
      medicoId = widget.controller.medicos.isNotEmpty
          ? widget.controller.medicos.first.id
          : null;
      tipoId = widget.controller.tipos.isNotEmpty
          ? widget.controller.tipos.first.id
          : null;
    }
  }

  @override
  void dispose() {
    obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: data,
    );
    if (picked != null) {
      setState(() => data = picked);
    }
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (pacienteId == null || medicoId == null || tipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione paciente, médico e tipo.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      if (isEdit) {
        await widget.controller.update(
          id: widget.recordId!,
          pacienteId: pacienteId!,
          medicoId: medicoId!,
          tipoId: tipoId!,
          dataRealizacao: data,
          status: status,
          observacoes: obsCtrl.text,
        );
      } else {
        await widget.controller.add(
          pacienteId: pacienteId!,
          medicoId: medicoId!,
          tipoId: tipoId!,
          dataRealizacao: data,
          status: status,
          observacoes: obsCtrl.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
      setState(() => saving = false);
      return;
    }

    if (!mounted) return;
    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit ? 'Registro atualizado.' : 'Registro criado.'),
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildResponsiveFields({required Widget left, required Widget right}) {
    final isWide = MediaQuery.of(context).size.width >= 760;

    if (!isWide) {
      return Column(
        children: [
          left,
          const SizedBox(height: AppSpacing.sm),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEdit ? 'Editar registro' : 'Novo registro',
      showNotificationsAction: false,
      child: FormPageShell(
        title: isEdit
            ? 'Atualização de procedimento realizado'
            : 'Cadastro de procedimento realizado',
        subtitle: 'Vincule corretamente paciente, médico e procedimento.',
        icon: Icons.assignment_outlined,
        child: Form(
          key: formKey,
          child: Column(
            children: [
              FormSectionCard(
                title: 'Vínculos do registro',
                subtitle: 'Contexto clínico principal do procedimento.',
                icon: Icons.link_outlined,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: pacienteId,
                      decoration: const InputDecoration(
                        labelText: 'Paciente',
                        prefixIcon: Icon(
                          Icons.person_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                      items: widget.controller.pacientes
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => pacienteId = v),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Selecione um paciente.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildResponsiveFields(
                      left: DropdownButtonFormField<String>(
                        value: medicoId,
                        decoration: const InputDecoration(
                          labelText: 'Médico',
                          prefixIcon: Icon(
                            Icons.medical_services_rounded,
                            size: AppIconSize.sm,
                          ),
                        ),
                        items: widget.controller.medicos
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => medicoId = v),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Selecione um médico.'
                            : null,
                      ),
                      right: DropdownButtonFormField<String>(
                        value: tipoId,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de procedimento',
                          prefixIcon: Icon(
                            Icons.category_rounded,
                            size: AppIconSize.sm,
                          ),
                        ),
                        items: widget.controller.tipos
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => tipoId = v),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Selecione um tipo.'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FormSectionCard(
                title: 'Execução clínica',
                subtitle: 'Registre data, status e observações.',
                icon: Icons.event_note_outlined,
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9E2EF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: AppIconSize.sm,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Data de realização',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    _fmtDate(data),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: AppIconSize.md,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<ProcedimentoStatus>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(
                          Icons.sync_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ProcedimentoStatus.pendenteImagens,
                          child: Text('Pendente de imagens'),
                        ),
                        DropdownMenuItem(
                          value: ProcedimentoStatus.emAndamento,
                          child: Text('Em andamento'),
                        ),
                        DropdownMenuItem(
                          value: ProcedimentoStatus.concluido,
                          child: Text('Concluído'),
                        ),
                        DropdownMenuItem(
                          value: ProcedimentoStatus.cancelado,
                          child: Text('Cancelado'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => status = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: obsCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        hintText: 'Registre observações complementares',
                        prefixIcon: Icon(
                          Icons.notes_rounded,
                          size: AppIconSize.sm,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormActionsBar(
                primaryLabel: isEdit
                    ? 'Salvar alterações'
                    : 'Cadastrar procedimento',
                onPrimary: saving ? null : _save,
                secondaryLabel: 'Cancelar',
                onSecondary: () => Navigator.pop(context),
                loading: saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$dd/$mm/$yyyy';
}
