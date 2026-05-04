import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';

import 'modules/admin_users/admin_user_create_screen.dart';
import 'modules/admin_users/admin_users_controller.dart';
import 'modules/admin_users/admin_users_list_screen.dart';
import 'modules/auth/forgot_password_screen.dart';
import 'modules/auth/login_screen.dart';
import 'modules/auth/reset_password_screen.dart';
import 'modules/dashboard/admin_dashboard_screen.dart';
import 'modules/dashboard/medico_dashboard_screen.dart';
import 'modules/procedures/procedures_screen.dart';
import 'modules/procedures/paciente_procedimentos_screen.dart';
import 'modules/logs/logs_screen.dart';
import 'modules/medicos/medico_form_screen.dart';
import 'modules/medicos/medicos_controller.dart';
import 'modules/medicos/medicos_list_screen.dart';
import 'modules/notifications/notifications_screen.dart';
import 'modules/pacientes/paciente_form_screen.dart';
import 'modules/pacientes/pacientes_controller.dart';
import 'modules/pacientes/pacientes_list_screen.dart';
import 'modules/procedure_images/procedure_images_screen.dart';
import 'modules/procedimentos_realizados/procedimento_realizado_form_screen.dart';
import 'modules/procedimentos_realizados/procedimentos_realizados_controller.dart';
import 'modules/procedimentos_realizados/procedimentos_realizados_list_screen.dart';
import 'modules/requests/requests_screen.dart';
import 'modules/solicitacoes_imagens/solicitacao_imagem_form_screen.dart';
import 'modules/solicitacoes_imagens/solicitacoes_imagens_list_screen.dart';
import 'modules/tipos_procedimento/tipo_procedimento_form_screen.dart';
import 'modules/tipos_procedimento/tipos_procedimento_controller.dart';
import 'modules/tipos_procedimento/tipos_procedimento_list_screen.dart';
import 'modules/auth/change_password_screen.dart';
import 'modules/profile/profile_screen.dart';

final authController = AuthController();

String _homeForRole(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return '/admin';
    case AppRole.medico:
      return '/medico';
    case AppRole.paciente:
      return '/paciente';
  }
}

class AuthResolutionErrorScreen extends StatelessWidget {
  const AuthResolutionErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro de acesso')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível resolver o perfil do usuário. '
            'Verifique as policies do Supabase e o cadastro em profiles.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: authController,
  redirect: (context, state) {
    final loggedIn = authController.isLoggedIn;
    final role = authController.role;
    final path = state.matchedLocation;

    final goingToLogin =
        path == '/login' || path == '/forgot' || path == '/reset-password';
    final goingToAuthError = path == '/auth-error';

    if (authController.booting) {
      return null;
    }

    if (!loggedIn) {
      return goingToLogin ? null : '/login';
    }

    if (path == '/reset-password') {
      return null;
    }

    if (role == null) {
      return goingToAuthError ? null : '/auth-error';
    }

    if (goingToLogin || goingToAuthError) {
      return _homeForRole(role);
    }

    if (path == '/logs' && role != AppRole.admin) {
      return _homeForRole(role);
    }

    if (path.startsWith('/admin-users') && role != AppRole.admin) {
      return _homeForRole(role);
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
      path: '/reset-password',
      builder: (_, __) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/auth-error',
      builder: (_, __) => const AuthResolutionErrorScreen(),
    ),

    GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
    GoRoute(path: '/medico', builder: (_, __) => const MedicoDashboardScreen()),
    GoRoute(
      path: '/paciente',
      builder: (_, __) => const PacienteDashboardScreen(),
    ),

    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/procedures',
      builder: (_, __) => const PacienteProcedimentosScreen(),
    ),
    GoRoute(path: '/requests', builder: (_, __) => const RequestsScreen()),
    GoRoute(path: '/logs', builder: (_, __) => const LogsScreen()),

    GoRoute(
      path: '/tipos-procedimento',
      builder: (_, __) => const TiposProcedimentoListScreen(),
    ),
    GoRoute(
      path: '/tipos-procedimento/novo',
      builder: (_, state) {
        final controller = state.extra as TiposProcedimentoController;
        return TipoProcedimentoFormScreen(controller: controller);
      },
    ),
    GoRoute(
      path: '/tipos-procedimento/editar/:id',
      builder: (_, state) {
        final controller = state.extra as TiposProcedimentoController;
        final id = state.pathParameters['id'];
        return TipoProcedimentoFormScreen(controller: controller, tipoId: id);
      },
    ),

    GoRoute(path: '/medicos', builder: (_, __) => const MedicosListScreen()),
    GoRoute(
      path: '/medicos/novo',
      builder: (_, state) {
        final controller = state.extra as MedicosController;
        return MedicoFormScreen(controller: controller);
      },
    ),
    GoRoute(
      path: '/medicos/editar/:id',
      builder: (_, state) {
        final controller = state.extra as MedicosController;
        final id = state.pathParameters['id'];
        return MedicoFormScreen(controller: controller, medicoId: id);
      },
    ),

    GoRoute(
      path: '/pacientes',
      builder: (_, __) => const PacientesListScreen(),
    ),
    GoRoute(
      path: '/pacientes/novo',
      builder: (_, state) {
        final controller = state.extra as PacientesController;
        return PacienteFormScreen(controller: controller);
      },
    ),
    GoRoute(
      path: '/pacientes/editar/:id',
      builder: (_, state) {
        final controller = state.extra as PacientesController;
        final id = state.pathParameters['id'];
        return PacienteFormScreen(controller: controller, pacienteId: id);
      },
    ),

    GoRoute(
      path: '/procedimentos-realizados',
      builder: (_, __) => const ProcedimentosRealizadosListScreen(),
    ),
    GoRoute(
      path: '/procedimentos-realizados/novo',
      builder: (_, state) {
        final controller = state.extra as ProcedimentosRealizadosController;
        return ProcedimentoRealizadoFormScreen(controller: controller);
      },
    ),
    GoRoute(
      path: '/procedimentos-realizados/editar/:id',
      builder: (_, state) {
        final controller = state.extra as ProcedimentosRealizadosController;
        final id = state.pathParameters['id'];
        return ProcedimentoRealizadoFormScreen(
          controller: controller,
          recordId: id,
        );
      },
    ),
    GoRoute(
      path: '/procedimentos-realizados/:id/imagens',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;

        return ProcedureImagesScreen(
          procedureId: id,
          procedureName: extra?['procedureName'] as String?,
        );
      },
    ),

    GoRoute(
      path: '/solicitacoes-imagens',
      builder: (_, __) => const SolicitacoesImagensListScreen(),
    ),
    GoRoute(
      path: '/solicitacoes-imagens/novo',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final procId = extra?['procId'] as String?;

        if (procId == null || procId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Procedimento não informado para a solicitação.'),
            ),
          );
        }

        return SolicitacaoImagemFormScreen(procedimentoRealizadoId: procId);
      },
    ),

    GoRoute(
      path: '/admin-users',
      builder: (_, __) => const AdminUsersListScreen(),
    ),
    GoRoute(
      path: '/admin-users/create',
      builder: (_, __) {
        final controller = AdminUsersController();
        return AdminUserCreateScreen(controller: controller);
      },
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: '/change-password',
      builder: (_, __) => const ChangePasswordScreen(),
    ),
  ],
);
