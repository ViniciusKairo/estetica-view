import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'procedure_image_model.dart';
import 'procedure_images_service.dart';

class ProcedureImagesController extends ChangeNotifier {
  final ProcedureImagesService _service;

  ProcedureImagesController(SupabaseClient client)
    : _service = ProcedureImagesService(client);

  final List<ProcedureImageModel> _images = [];
  List<ProcedureImageModel> get images => List.unmodifiable(_images);

  bool loading = false;
  bool openingImage = false;
  bool uploading = false;
  String? errorMessage;

  List<ProcedureImageModel> get antes =>
      _images.where((e) => e.imageType == 'antes').toList();

  List<ProcedureImageModel> get depois =>
      _images.where((e) => e.imageType == 'depois').toList();

  Future<void> loadByProcedure(String procedureId) async {
    loading = true;
    errorMessage = null;
    _images.clear();
    notifyListeners();

    try {
      final list = await _service.listByProcedure(procedureId);
      _images
        ..clear()
        ..addAll(list);
    } catch (e) {
      errorMessage = 'Falha ao carregar imagens do procedimento.';
      debugPrint('ProcedureImagesController.loadByProcedure error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadImage({
    required String procedureId,
    required String imageType,
    required XFile file,
  }) async {
    uploading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final created = await _service.uploadImage(
        procedureId: procedureId,
        imageType: imageType,
        originalFile: file,
      );

      _images.insert(0, created);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('ProcedureImagesController.uploadImage error: $e');
      return false;
    } finally {
      uploading = false;
      notifyListeners();
    }
  }

  Future<String?> getSignedUrl({required String imageId}) async {
    openingImage = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = await _service.getSignedUrl(imageId: imageId);
      return url;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('ProcedureImagesController.getSignedUrl error: $e');
      return null;
    } finally {
      openingImage = false;
      notifyListeners();
    }
  }
}
