import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';

enum AuditAction {
  create,
  update,
  delete,
  login,
  logout,
  access,
  approval,
  other,
}

AuditAction _actionFromDb(String? action) {
  final value = (action ?? '').toUpperCase();

  if (value.contains('CREATE') || value.contains('INSERT')) {
    return AuditAction.create;
  }
  if (value.contains('UPDATE')) {
    return AuditAction.update;
  }
  if (value.contains('DELETE') || value.contains('REMOVE')) {
    return AuditAction.delete;
  }
  if (value.contains('LOGIN')) {
    return AuditAction.login;
  }
  if (value.contains('LOGOUT')) {
    return AuditAction.logout;
  }
  if (value.contains('APPROVE') ||
      value.contains('REPROVE') ||
      value.contains('REJECT') ||
      value.contains('REVOKE')) {
    return AuditAction.approval;
  }
  if (value.contains('ACCESS') ||
      value.contains('SIGNED_URL') ||
      value.contains('VIEW') ||
      value.contains('READ')) {
    return AuditAction.access;
  }

  return AuditAction.other;
}

class AuditLogModel {
  final String id;
  final String? actorProfileId;
  final String? actorRole;
  final String rawAction;
  final AuditAction action;
  final String entity;
  final String? entityId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    this.actorProfileId,
    this.actorRole,
    required this.rawAction,
    required this.action,
    required this.entity,
    this.entityId,
    this.description,
    this.metadata,
    required this.createdAt,
  });
}

class LogsController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final AuthController _authController;

  List<AuditLogModel> _all = [];
  bool loading = false;
  String _search = '';
  String _actionFilter = 'todas';

  LogsController(this._authController);

  String get search => _search;
  String get actionFilter => _actionFilter;

  List<AuditLogModel> get items {
    Iterable<AuditLogModel> result = _all;

    if (_actionFilter != 'todas') {
      switch (_actionFilter) {
        case 'create':
          result = result.where((e) => e.action == AuditAction.create);
          break;
        case 'update':
          result = result.where((e) => e.action == AuditAction.update);
          break;
        case 'delete':
          result = result.where((e) => e.action == AuditAction.delete);
          break;
        case 'login':
          result = result.where((e) => e.action == AuditAction.login);
          break;
        case 'logout':
          result = result.where((e) => e.action == AuditAction.logout);
          break;
        case 'access':
          result = result.where((e) => e.action == AuditAction.access);
          break;
        case 'approval':
          result = result.where((e) => e.action == AuditAction.approval);
          break;
      }
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      result = result.where((e) {
        return e.entity.toLowerCase().contains(q) ||
            e.rawAction.toLowerCase().contains(q) ||
            (e.actorRole?.toLowerCase().contains(q) ?? false) ||
            (e.description?.toLowerCase().contains(q) ?? false) ||
            (e.entityId?.toLowerCase().contains(q) ?? false);
      });
    }

    final list = result.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> init() async {
    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (_authController.role != AppRole.admin) {
      _all = [];
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final res = await _client
          .from('audit_logs')
          .select('''
            id,
            actor_profile_id,
            actor_role,
            action,
            entity_type,
            entity_id,
            description,
            metadata,
            created_at
          ''')
          .order('created_at', ascending: false)
          .limit(100);

      _all = (res as List).map((e) {
        final row = Map<String, dynamic>.from(e as Map);

        final metadataRaw = row['metadata'];
        final metadata = metadataRaw is Map<String, dynamic>
            ? metadataRaw
            : metadataRaw is Map
            ? Map<String, dynamic>.from(metadataRaw)
            : null;

        return AuditLogModel(
          id: row['id'].toString(),
          actorProfileId: row['actor_profile_id']?.toString(),
          actorRole: row['actor_role']?.toString(),
          rawAction: row['action']?.toString() ?? '',
          action: _actionFromDb(row['action']?.toString()),
          entity: row['entity_type']?.toString() ?? '',
          entityId: row['entity_id']?.toString(),
          description: row['description']?.toString(),
          metadata: metadata,
          createdAt: DateTime.parse(row['created_at'].toString()),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao carregar logs: $e');
      _all = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setActionFilter(String value) {
    _actionFilter = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadLogs();
  }
}
