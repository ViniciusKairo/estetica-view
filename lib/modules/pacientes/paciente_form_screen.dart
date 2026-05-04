import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_scaffold.dart';
import '../../ui/widgets/form_actions_bar.dart';
import '../../ui/widgets/form_page_shell.dart';
import '../../ui/widgets/form_section_card.dart';
import 'pacientes_controller.dart';

class PacienteFormScreen extends StatefulWidget {
  final PacientesController controller;
  final String? pacienteId;

  const PacienteFormScreen({
    super.key,
    required this.controller,
    this.pacienteId,
  });

  @override
  State<PacienteFormScreen> createState() => _PacienteFormScreenState();
}

class _PacienteFormScreenState extends State<PacienteFormScreen> {
  final form = GlobalKey<FormState>();

  final nome = TextEditingController();
  final email = TextEditingController();
  final telefone = TextEditingController();
  final senha = TextEditingController();
  final confirmarSenha = TextEditingController();

  bool ativo = true;
  bool salvando = false;
  bool obscureSenha = true;
  bool obscureConfirmar = true;

  bool get isEdit => widget.pacienteId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (!isEdit) return;

    final paciente = widget.controller.findById(widget.pacienteId!);
    if (paciente == null) return;

    nome.text = paciente.nome;
    email.text = paciente.email;
    telefone.text = paciente.telefone;
    ativo = paciente.ativo;
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    telefone.dispose();
    senha.dispose();
    confirmarSenha.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;

    if (!isEdit) {
      if (senha.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe a senha inicial.')),
        );
        return;
      }

      if (senha.text.trim() != confirmarSenha.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem.')),
        );
        return;
      }
    }

    setState(() => salvando = true);

    try {
      if (isEdit) {
        await widget.controller.updatePaciente(
          id: widget.pacienteId!,
          nome: nome.text,
          email: email.text,
          telefone: telefone.text,
          ativo: ativo,
        );
      } else {
        await widget.controller.addPaciente(
          nome: nome.text,
          email: email.text,
          telefone: telefone.text,
          ativo: ativo,
          password: senha.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
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
      title: isEdit ? 'Editar paciente' : 'Novo paciente',
      showNotificationsAction: false,
      child: FormPageShell(
        title: isEdit ? 'Atualização de paciente' : 'Cadastro de paciente',
        subtitle: 'Preencha apenas os dados essenciais do paciente.',
        icon: Icons.people_outline_rounded,
        child: Form(
          key: form,
          child: Column(
            children: [
              FormSectionCard(
                title: 'Identificação',
                subtitle: 'Dados básicos de cadastro.',
                icon: Icons.person_outline_rounded,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nome,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        hintText: 'Digite o nome do paciente',
                        prefixIcon: Icon(
                          Icons.person_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe o nome'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isEdit,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'Digite o e-mail',
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o email';
                        }
                        if (!v.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FormSectionCard(
                title: 'Contato',
                subtitle: 'Informações operacionais.',
                icon: Icons.contact_phone_outlined,
                child: Column(
                  children: [
                    TextFormField(
                      controller: telefone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        hintText: 'Digite o telefone',
                        prefixIcon: Icon(
                          Icons.phone_rounded,
                          size: AppIconSize.sm,
                        ),
                      ),
                    ),
                    if (!isEdit) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildResponsiveFields(
                        left: TextFormField(
                          controller: senha,
                          obscureText: obscureSenha,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Senha inicial',
                            hintText: 'Digite a senha inicial',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: AppIconSize.sm,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => obscureSenha = !obscureSenha);
                              },
                              icon: Icon(
                                obscureSenha
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: AppIconSize.sm,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (isEdit) return null;
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe a senha';
                            }
                            if (v.trim().length < 6) {
                              return 'Mínimo de 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        right: TextFormField(
                          controller: confirmarSenha,
                          obscureText: obscureConfirmar,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            hintText: 'Repita a senha',
                            prefixIcon: const Icon(
                              Icons.lock_reset_rounded,
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
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: AppIconSize.sm,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (isEdit) return null;
                            if (v == null || v.trim().isEmpty) {
                              return 'Confirme a senha';
                            }
                            if (v.trim() != senha.text.trim()) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Paciente ativo'),
                      subtitle: const Text(
                        'Quando inativo, o acesso ao sistema fica bloqueado.',
                      ),
                      value: ativo,
                      onChanged: (value) => setState(() => ativo = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormActionsBar(
                primaryLabel: isEdit
                    ? 'Salvar alterações'
                    : 'Cadastrar paciente',
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
