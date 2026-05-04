import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/form_actions_bar.dart';
import '../../ui/widgets/form_page_shell.dart';
import '../../ui/widgets/form_section_card.dart';
import 'tipos_procedimento_controller.dart';

class TipoProcedimentoFormScreen extends StatefulWidget {
  final TiposProcedimentoController controller;
  final String? tipoId;

  const TipoProcedimentoFormScreen({
    super.key,
    required this.controller,
    this.tipoId,
  });

  @override
  State<TipoProcedimentoFormScreen> createState() =>
      _TipoProcedimentoFormScreenState();
}

class _TipoProcedimentoFormScreenState
    extends State<TipoProcedimentoFormScreen> {
  final form = GlobalKey<FormState>();

  final nome = TextEditingController();
  final descricao = TextEditingController();

  bool ativo = true;
  bool salvando = false;

  bool get isEdit => widget.tipoId != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final tipo = widget.controller.findById(widget.tipoId!);

      if (tipo != null) {
        nome.text = tipo.nome;
        descricao.text = tipo.descricao;
        ativo = tipo.ativo;
      }
    }
  }

  @override
  void dispose() {
    nome.dispose();
    descricao.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;

    setState(() => salvando = true);

    try {
      if (isEdit) {
        await widget.controller.updateTipo(
          id: widget.tipoId!,
          nome: nome.text,
          descricao: descricao.text,
          ativo: ativo,
        );
      } else {
        await widget.controller.addTipo(
          nome: nome.text,
          descricao: descricao.text,
          ativo: ativo,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEdit ? 'Editar procedimento' : 'Novo procedimento',
      showNotificationsAction: false,
      child: FormPageShell(
        title: isEdit
            ? 'Atualização de tipo de procedimento'
            : 'Cadastro de tipo de procedimento',
        subtitle: 'Mantenha o catálogo claro e consistente.',
        icon: Icons.category_outlined,
        child: Form(
          key: form,
          child: Column(
            children: [
              FormSectionCard(
                title: 'Dados do catálogo',
                subtitle: 'Informações usadas nas rotinas de seleção.',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nome,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Digite o nome do procedimento',
                        prefixIcon: Icon(
                          Icons.label_outline_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: descricao,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Descreva o procedimento',
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
              const SizedBox(height: AppSpacing.sm),
              FormSectionCard(
                title: 'Disponibilidade',
                subtitle:
                    'Defina se o tipo ficará disponível para novas operações.',
                icon: Icons.toggle_on_outlined,
                child: SwitchListTile.adaptive(
                  value: ativo,
                  onChanged: (v) => setState(() => ativo = v),
                  title: const Text(
                    'Procedimento ativo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    ativo
                        ? 'O tipo estará disponível para novos registros.'
                        : 'O tipo ficará indisponível para novas operações.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormActionsBar(
                primaryLabel: isEdit ? 'Salvar alterações' : 'Cadastrar tipo',
                onPrimary: salvando ? null : salvar,
                secondaryLabel: 'Cancelar',
                onSecondary: () => Navigator.pop(context),
                loading: salvando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
