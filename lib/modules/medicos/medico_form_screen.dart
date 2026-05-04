import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/form_actions_bar.dart';
import '../../ui/widgets/form_page_shell.dart';
import '../../ui/widgets/form_section_card.dart';
import 'medico_model.dart';
import 'medicos_controller.dart';

class MedicoFormScreen extends StatefulWidget {
  final MedicosController controller;
  final String? medicoId;

  const MedicoFormScreen({super.key, required this.controller, this.medicoId});

  @override
  State<MedicoFormScreen> createState() => _MedicoFormScreenState();
}

class _MedicoFormScreenState extends State<MedicoFormScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nomeCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController crmCtrl;
  late final TextEditingController especializacaoCtrl;
  final TextEditingController senhaCtrl = TextEditingController();
  final TextEditingController confirmarSenhaCtrl = TextEditingController();

  bool ativo = true;
  bool saving = false;
  MedicoModel? medico;

  bool obscureSenha = true;
  bool obscureConfirmar = true;

  bool get isEdit => widget.medicoId != null;

  @override
  void initState() {
    super.initState();

    medico = isEdit ? widget.controller.findById(widget.medicoId!) : null;

    nomeCtrl = TextEditingController(text: medico?.nome ?? '');
    emailCtrl = TextEditingController(text: medico?.email ?? '');
    crmCtrl = TextEditingController(text: medico?.crm ?? '');
    especializacaoCtrl = TextEditingController(
      text: medico?.especializacao ?? '',
    );
    ativo = medico?.ativo ?? true;
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    crmCtrl.dispose();
    especializacaoCtrl.dispose();
    senhaCtrl.dispose();
    confirmarSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => saving = true);

    try {
      if (isEdit && medico != null) {
        await widget.controller.updateMedico(
          id: medico!.id,
          nome: nomeCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          crm: crmCtrl.text.trim(),
          especializacao: especializacaoCtrl.text.trim(),
          ativo: ativo,
        );
      } else {
        await widget.controller.addMedico(
          nome: nomeCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          crm: crmCtrl.text.trim(),
          especializacao: especializacaoCtrl.text.trim(),
          password: senhaCtrl.text.trim(),
          ativo: ativo,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Médico atualizado com sucesso.'
                : 'Médico cadastrado com sucesso.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
      title: isEdit ? 'Editar médico' : 'Novo médico',
      showNotificationsAction: false,
      child: FormPageShell(
        title: isEdit ? 'Atualização de médico' : 'Cadastro de médico',
        subtitle: isEdit
            ? 'Atualize os dados principais do profissional.'
            : 'Defina os dados principais e a senha de acesso inicial.',
        icon: Icons.medical_services_outlined,
        child: Form(
          key: formKey,
          child: Column(
            children: [
              FormSectionCard(
                title: 'Identificação',
                subtitle: 'Dados básicos de cadastro.',
                icon: Icons.badge_outlined,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nomeCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        hintText: 'Digite o nome do médico',
                        prefixIcon: Icon(
                          Icons.person_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do médico.';
                        }
                        if (value.trim().length < 3) {
                          return 'Nome muito curto.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'Digite o e-mail profissional',
                        prefixIcon: Icon(
                          Icons.mail_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Informe o e-mail.';
                        if (!text.contains('@')) return 'E-mail inválido.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FormSectionCard(
                title: 'Dados profissionais',
                subtitle: 'Informações para operação e busca.',
                icon: Icons.verified_outlined,
                child: _buildResponsiveFields(
                  left: TextFormField(
                    controller: crmCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'CRM',
                      hintText: 'Digite o CRM',
                      prefixIcon: Icon(
                        Icons.assignment_ind_rounded,
                        size: AppIconSize.sm,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o CRM.';
                      }
                      if (value.trim().length < 4) {
                        return 'CRM deve ter pelo menos 4 caracteres.';
                      }
                      return null;
                    },
                  ),
                  right: TextFormField(
                    controller: especializacaoCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Especialização',
                      hintText: 'Digite a especialização',
                      prefixIcon: Icon(
                        Icons.local_hospital_rounded,
                        size: AppIconSize.sm,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a especialização.';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              if (!isEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                FormSectionCard(
                  title: 'Acesso inicial',
                  subtitle: 'Defina a senha inicial do profissional.',
                  icon: Icons.lock_outline_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: senhaCtrl,
                        obscureText: obscureSenha,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Senha de acesso',
                          hintText: 'Digite a senha inicial',
                          prefixIcon: const Icon(
                            Icons.lock_rounded,
                            size: AppIconSize.sm,
                          ),
                          helperText: 'Mínimo de 6 caracteres',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => obscureSenha = !obscureSenha);
                            },
                            icon: Icon(
                              obscureSenha
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: AppIconSize.sm,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a senha de acesso.';
                          }
                          if (value.trim().length < 6) {
                            return 'Senha deve ter pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: confirmarSenhaCtrl,
                        obscureText: obscureConfirmar,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          hintText: 'Repita a senha informada',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: AppIconSize.sm,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () => obscureConfirmar = !obscureConfirmar,
                              );
                            },
                            icon: Icon(
                              obscureConfirmar
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: AppIconSize.sm,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Confirme a senha.';
                          }
                          if (value != senhaCtrl.text) {
                            return 'As senhas não coincidem.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              FormSectionCard(
                title: 'Status operacional',
                subtitle: 'Defina a disponibilidade do cadastro.',
                icon: Icons.toggle_on_outlined,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: ativo,
                  onChanged: (v) => setState(() => ativo = v),
                  title: const Text(
                    'Médico ativo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    ativo
                        ? 'O cadastro ficará disponível para operações.'
                        : 'O cadastro ficará indisponível para uso operacional.',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormActionsBar(
                primaryLabel: isEdit ? 'Salvar alterações' : 'Cadastrar médico',
                onPrimary: saving ? null : _save,
                secondaryLabel: 'Cancelar',
                onSecondary: () => Navigator.of(context).pop(),
                loading: saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
