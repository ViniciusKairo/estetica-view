import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_router.dart';
import '../../auth/auth_controller.dart';
import 'procedure_image_model.dart';
import 'procedure_images_controller.dart';

class ProcedureImagesScreen extends StatelessWidget {
  final String procedureId;
  final String? procedureName;

  const ProcedureImagesScreen({
    super.key,
    required this.procedureId,
    this.procedureName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ProcedureImagesController(Supabase.instance.client)
            ..loadByProcedure(procedureId),
      child: _ProcedureImagesView(
        procedureId: procedureId,
        procedureName: procedureName,
      ),
    );
  }
}

class _ProcedureImagesView extends StatelessWidget {
  final String procedureId;
  final String? procedureName;

  const _ProcedureImagesView({
    required this.procedureId,
    required this.procedureName,
  });

  bool get _isPatient => authController.role == AppRole.paciente;

  Future<void> _pickAndUpload(BuildContext context) async {
    if (_isPatient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente não pode adicionar imagens ao procedimento.'),
        ),
      );
      return;
    }

    final controller = context.read<ProcedureImagesController>();
    final picker = ImagePicker();

    final imageType = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E2EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                title: Text(
                  'Adicionar imagem',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Selecione primeiro se a imagem é de antes ou depois.',
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Imagem de antes'),
                  subtitle: const Text(
                    'Registrar estágio anterior ao procedimento.',
                  ),
                  onTap: () => Navigator.pop(context, 'antes'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Imagem de depois'),
                  subtitle: const Text(
                    'Registrar estágio posterior ao procedimento.',
                  ),
                  onTap: () => Navigator.pop(context, 'depois'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (imageType == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E2EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                title: Text(
                  'Origem da imagem',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Escolha se deseja tirar a foto agora ou selecionar da galeria.',
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tirar foto agora'),
                  subtitle: const Text('Abrir a câmera do aparelho.'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Escolher da galeria'),
                  subtitle: const Text('Selecionar uma imagem existente.'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (picked == null) return;

    if (!context.mounted) return;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ConfirmImageScreen(file: picked, imageType: imageType),
      ),
    );

    if (confirmed != true) return;

    final ok = await controller.uploadImage(
      procedureId: procedureId,
      imageType: imageType,
      file: picked,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Imagem enviada com sucesso.'
              : controller.errorMessage ?? 'Falha ao enviar imagem.',
        ),
      ),
    );
  }

  Future<void> _openComparison(BuildContext context) async {
    final controller = context.read<ProcedureImagesController>();

    if (controller.antes.isEmpty || controller.depois.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'É necessário ter ao menos uma imagem de antes e uma de depois.',
          ),
        ),
      );
      return;
    }

    final selection = await showModalBottomSheet<_ComparisonSelectionResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ComparisonSelectionSheet(
        beforeImages: controller.antes,
        afterImages: controller.depois,
      ),
    );

    if (selection == null) return;

    final beforeUrl = await controller.getSignedUrl(
      imageId: selection.beforeImage.id,
    );
    final afterUrl = await controller.getSignedUrl(
      imageId: selection.afterImage.id,
    );

    if (!context.mounted) return;

    if (beforeUrl == null ||
        beforeUrl.isEmpty ||
        afterUrl == null ||
        afterUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ??
                'Falha ao carregar imagens para comparação.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BeforeAfterComparisonScreen(
          beforeUrl: beforeUrl,
          afterUrl: afterUrl,
          procedureTitle: procedureName ?? 'Procedimento',
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    if (_isPatient) {
      context.go('/procedures');
      return;
    }

    context.go('/procedimentos-realizados');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProcedureImagesController>();
    final isWide = MediaQuery.of(context).size.width >= 920;
    final headerTitle = procedureName?.trim().isNotEmpty == true
        ? procedureName!
        : 'Procedimento clínico';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _handleBack(context),
        ),
        title: const Text('Imagens do procedimento'),
        actions: [
          if (controller.antes.isNotEmpty && controller.depois.isNotEmpty)
            IconButton(
              tooltip: 'Comparar',
              onPressed: () => _openComparison(context),
              icon: const Icon(Icons.compare_rounded),
            ),
        ],
      ),
      floatingActionButton: _isPatient
          ? null
          : FloatingActionButton.extended(
              onPressed: controller.uploading
                  ? null
                  : () => _pickAndUpload(context),
              icon: controller.uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_rounded),
              label: Text(
                controller.uploading ? 'Enviando...' : 'Adicionar imagem',
              ),
            ),
      body: Builder(
        builder: (_) {
          if (controller.loading) {
            return const _LoadingView(message: 'Carregando imagens...');
          }

          if (controller.errorMessage != null && controller.images.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _EmptyLikeState(
                  icon: Icons.broken_image_outlined,
                  title: 'Falha ao carregar imagens',
                  message: controller.errorMessage!,
                  actionLabel: 'Tentar novamente',
                  onAction: () => controller.loadByProcedure(procedureId),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadByProcedure(procedureId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  title: headerTitle,
                  subtitle:
                      'Gerencie registros fotográficos clínicos e acompanhe a evolução visual do procedimento.',
                  icon: Icons.photo_library_outlined,
                  trailing: _HeaderSummary(
                    beforeCount: controller.antes.length,
                    afterCount: controller.depois.length,
                    totalCount: controller.images.length,
                  ),
                ),
                const SizedBox(height: 14),
                if (controller.errorMessage != null)
                  _ErrorBanner(message: controller.errorMessage!),
                if (controller.images.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: _EmptyLikeState(
                      icon: Icons.photo_size_select_actual_outlined,
                      title: 'Nenhuma imagem cadastrada',
                      message:
                          'Nenhuma imagem foi disponibilizada para este procedimento até o momento.',
                    ),
                  )
                else ...[
                  if (controller.antes.isNotEmpty &&
                      controller.depois.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: isWide
                            ? Row(
                                children: [
                                  const Expanded(
                                    child: _HighlightBlock(
                                      icon: Icons.compare_arrows_rounded,
                                      title: 'Comparação disponível',
                                      subtitle:
                                          'Escolha exatamente quais imagens de antes e depois deseja comparar.',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 220,
                                    child: FilledButton.icon(
                                      onPressed: () => _openComparison(context),
                                      icon: const Icon(Icons.compare_rounded),
                                      label: const Text('Abrir comparação'),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _HighlightBlock(
                                    icon: Icons.compare_arrows_rounded,
                                    title: 'Comparação disponível',
                                    subtitle:
                                        'Escolha exatamente quais imagens de antes e depois deseja comparar.',
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    onPressed: () => _openComparison(context),
                                    icon: const Icon(Icons.compare_rounded),
                                    label: const Text('Abrir comparação'),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _ImageSection(
                    title: 'Antes',
                    subtitle: 'Registros do estado anterior ao procedimento.',
                    color: const Color(0xFFD97706),
                    icon: Icons.history_toggle_off_rounded,
                    images: controller.antes,
                  ),
                  const SizedBox(height: 18),
                  _ImageSection(
                    title: 'Depois',
                    subtitle:
                        'Registros do resultado posterior ao procedimento.',
                    color: const Color(0xFF15803D),
                    icon: Icons.auto_awesome_outlined,
                    images: controller.depois,
                  ),
                  const SizedBox(height: 100),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConfirmImageScreen extends StatelessWidget {
  final XFile file;
  final String imageType;

  const _ConfirmImageScreen({required this.file, required this.imageType});

  String get _typeLabel => imageType == 'antes' ? 'Antes' : 'Depois';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar imagem')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Revise a foto antes de enviar. Tipo selecionado: $_typeLabel.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    file.path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFFF1F5F9),
                        alignment: Alignment.center,
                        child: const Text(
                          'Não foi possível carregar a prévia.',
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Descartar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Usar esta foto'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  final int beforeCount;
  final int afterCount;
  final int totalCount;

  const _HeaderSummary({
    required this.beforeCount,
    required this.afterCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;

    return SizedBox(
      width: isWide ? 290 : double.infinity,
      child: Card(
        color: const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryRow(label: 'Total', value: totalCount.toString()),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Antes', value: beforeCount.toString()),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Depois', value: afterCount.toString()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _HighlightBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HighlightBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<ProcedureImageModel> images;

  const _ImageSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusBadge(label: title, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (images.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nenhuma imagem registrada nesta categoria.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...images.map(
            (image) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ImageCard(image: image),
            ),
          ),
      ],
    );
  }
}

class _ImageCard extends StatefulWidget {
  final ProcedureImageModel image;

  const _ImageCard({required this.image});

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  String? _signedUrl;
  bool _loadingThumb = true;
  String? _thumbError;
  bool hovering = false;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final controller = context.read<ProcedureImagesController>();

    try {
      final url = await controller.getSignedUrl(imageId: widget.image.id);
      if (!mounted) return;

      setState(() {
        _signedUrl = url;
        _loadingThumb = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _thumbError = 'Falha ao carregar miniatura';
        _loadingThumb = false;
      });
    }
  }

  String _label() {
    switch (widget.image.imageType) {
      case 'antes':
        return 'Antes';
      case 'depois':
        return 'Depois';
      default:
        return 'Imagem';
    }
  }

  String _secondaryText() {
    final size = widget.image.fileSize;
    if (size == null) return 'Toque para visualizar';
    final kb = (size / 1024).toStringAsFixed(1);
    return '$kb KB';
  }

  String _dateText() {
    final createdAt = widget.image.createdAt;
    if (createdAt == null) return 'Data não informada';
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  Future<void> _openViewer(BuildContext context) async {
    String? signedUrl = _signedUrl;

    if (signedUrl == null || signedUrl.isEmpty) {
      final controller = context.read<ProcedureImagesController>();
      signedUrl = await controller.getSignedUrl(imageId: widget.image.id);
    }

    if (!context.mounted) return;

    if (signedUrl == null || signedUrl.isEmpty) {
      final controller = context.read<ProcedureImagesController>();
      final msg = controller.errorMessage ?? 'Falha ao abrir imagem.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _ProcedureImageViewerScreen(title: _label(), imageUrl: signedUrl!),
      ),
    );
  }

  Widget _buildThumb() {
    if (_loadingThumb) {
      return Container(
        width: 94,
        height: 94,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_signedUrl == null || _signedUrl!.isEmpty || _thumbError != null) {
      return Container(
        width: 94,
        height: 94,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.broken_image_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        _signedUrl!,
        width: 94,
        height: 94,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 94,
            height: 94,
            color: const Color(0xFFF1F5F9),
            child: const Icon(Icons.broken_image_outlined),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 94,
            height: 94,
            color: const Color(0xFFF8FAFC),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.image.imageType == 'antes'
        ? const Color(0xFFD97706)
        : const Color(0xFF15803D);

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        scale: hovering ? 1.01 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _openViewer(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _buildThumb(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusBadge(label: _label(), color: typeColor),
                        const SizedBox(height: 10),
                        Text(
                          _secondaryText(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _dateText(),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Toque para abrir em tela cheia.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
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

class _ProcedureImageViewerScreen extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _ProcedureImageViewerScreen({
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        color: Colors.black,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível exibir a imagem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonSelectionResult {
  final ProcedureImageModel beforeImage;
  final ProcedureImageModel afterImage;

  const _ComparisonSelectionResult({
    required this.beforeImage,
    required this.afterImage,
  });
}

class _ComparisonSelectionSheet extends StatefulWidget {
  final List<ProcedureImageModel> beforeImages;
  final List<ProcedureImageModel> afterImages;

  const _ComparisonSelectionSheet({
    required this.beforeImages,
    required this.afterImages,
  });

  @override
  State<_ComparisonSelectionSheet> createState() =>
      _ComparisonSelectionSheetState();
}

class _ComparisonSelectionSheetState extends State<_ComparisonSelectionSheet> {
  late String _selectedBeforeId;
  late String _selectedAfterId;

  @override
  void initState() {
    super.initState();
    _selectedBeforeId = widget.beforeImages.first.id;
    _selectedAfterId = widget.afterImages.first.id;
  }

  ProcedureImageModel get _selectedBefore =>
      widget.beforeImages.firstWhere((e) => e.id == _selectedBeforeId);

  ProcedureImageModel get _selectedAfter =>
      widget.afterImages.firstWhere((e) => e.id == _selectedAfterId);

  String _formatDate(DateTime? date) {
    if (date == null) return 'Data não informada';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _fileSizeLabel(int? size) {
    if (size == null) return 'Tamanho não informado';
    final kb = size / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E2EF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Selecionar imagens da comparação',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Escolha exatamente qual imagem de antes e qual imagem de depois deseja comparar.',
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _ComparisonSelectorGroup(
                    title: 'Imagem de antes',
                    color: const Color(0xFFD97706),
                    images: widget.beforeImages,
                    selectedId: _selectedBeforeId,
                    onSelected: (id) => setState(() => _selectedBeforeId = id),
                    formatDate: _formatDate,
                    fileSizeLabel: _fileSizeLabel,
                  ),
                  const SizedBox(height: 16),
                  _ComparisonSelectorGroup(
                    title: 'Imagem de depois',
                    color: const Color(0xFF15803D),
                    images: widget.afterImages,
                    selectedId: _selectedAfterId,
                    onSelected: (id) => setState(() => _selectedAfterId = id),
                    formatDate: _formatDate,
                    fileSizeLabel: _fileSizeLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _ComparisonSelectionResult(
                          beforeImage: _selectedBefore,
                          afterImage: _selectedAfter,
                        ),
                      );
                    },
                    icon: const Icon(Icons.compare_rounded),
                    label: const Text('Comparar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonSelectorGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<ProcedureImageModel> images;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final String Function(DateTime?) formatDate;
  final String Function(int?) fileSizeLabel;

  const _ComparisonSelectorGroup({
    required this.title,
    required this.color,
    required this.images,
    required this.selectedId,
    required this.onSelected,
    required this.formatDate,
    required this.fileSizeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBadge(label: title, color: color),
            const SizedBox(height: 12),
            ...images.map(
              (image) => RadioListTile<String>(
                value: image.id,
                groupValue: selectedId,
                onChanged: (value) {
                  if (value != null) onSelected(value);
                },
                contentPadding: EdgeInsets.zero,
                title: Text(
                  formatDate(image.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(fileSizeLabel(image.fileSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeforeAfterComparisonScreen extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;
  final String procedureTitle;

  const _BeforeAfterComparisonScreen({
    required this.beforeUrl,
    required this.afterUrl,
    required this.procedureTitle,
  });

  @override
  State<_BeforeAfterComparisonScreen> createState() =>
      _BeforeAfterComparisonScreenState();
}

class _BeforeAfterComparisonScreenState
    extends State<_BeforeAfterComparisonScreen> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareComparison() async {
    try {
      setState(() => _sharing = true);

      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Não foi possível capturar a comparação.');
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Falha ao gerar imagem para compartilhamento.');
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'comparacao_antes_depois.png',
        ),
      ], text: 'Comparação antes/depois - ${widget.procedureTitle}');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao compartilhar: $e')));
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparação antes/depois'),
        actions: [
          IconButton(
            tooltip: 'Compartilhar comparação',
            onPressed: _sharing ? null : _shareComparison,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _captureKey,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ComparisonPane(
                          title: 'Antes',
                          imageUrl: widget.beforeUrl,
                          backgroundColor: bg,
                          accentColor: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ComparisonPane(
                          title: 'Depois',
                          imageUrl: widget.afterUrl,
                          backgroundColor: bg,
                          accentColor: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ComparisonPaneMobile(
                    title: 'Antes',
                    imageUrl: widget.beforeUrl,
                    backgroundColor: bg,
                    accentColor: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 16),
                  _ComparisonPaneMobile(
                    title: 'Depois',
                    imageUrl: widget.afterUrl,
                    backgroundColor: bg,
                    accentColor: const Color(0xFF15803D),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ComparisonPane extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color backgroundColor;
  final Color accentColor;

  const _ComparisonPane({
    required this.title,
    required this.imageUrl,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _StatusBadge(label: title, color: accentColor),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Não foi possível exibir a imagem.'),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonPaneMobile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color backgroundColor;
  final Color accentColor;

  const _ComparisonPaneMobile({
    required this.title,
    required this.imageUrl,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _StatusBadge(label: title, color: accentColor),
            ),
            const SizedBox(height: 12),
            Container(
              height: 360,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Não foi possível exibir a imagem.'),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 760;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: scheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _HeaderTexts(title: title, subtitle: subtitle),
                  ),
                  const SizedBox(width: 16),
                  trailing,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: scheme.primary),
                  ),
                  const SizedBox(height: 14),
                  _HeaderTexts(title: title, subtitle: subtitle),
                  const SizedBox(height: 16),
                  trailing,
                ],
              ),
      ),
    );
  }
}

class _HeaderTexts extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderTexts({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

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

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyLikeState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyLikeState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: scheme.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
