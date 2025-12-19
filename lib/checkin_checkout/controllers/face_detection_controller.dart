import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceScannerController {
  late CameraController cameraController;
  late CameraDescription selectedCamera;

  var faceSdk = FaceSDK.instance;

  bool _isInitialized = false;

  Future initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Permiso de cámara no concedido');
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No hay cámaras disponibles');
      }
      selectedCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController.initialize();
      _isInitialized = true;
      log('Cámara inicializada correctamente');
    } catch (e) {
      log('Error al inicializar la cámara: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<XFile?> captureImage() async {
    if (!_isInitialized || !cameraController.value.isInitialized) {
      log('La cámara no está inicializada o ya fue liberada');
      return null;
    }
    try {
      if (cameraController.value.isTakingPicture) {
        log('La cámara ya está tomando una foto');
        return null;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      final image = await cameraController.takePicture();
      log('Imagen capturada correctamente en ${image.path}');
      final file = File(image.path);
      if (!file.existsSync()) {
        throw Exception('No se encontró el archivo de la imagen capturada');
      }
      final length = await file.length();
      if (length == 0) {
        throw Exception('El archivo de la imagen capturada está vacío');
      }
      return image;
    } catch (e) {
      log('Error al capturar imagen: $e');
      return null;
    }
  }

  Future<bool> compareFaces(File capturedImageFile, String storedImageBase64) async {
    try {
      if (!await capturedImageFile.exists()) {
        throw Exception('No se encontró el archivo de la imagen capturada en: ${capturedImageFile.path}');
      }
      final storedImageBytes = base64Decode(storedImageBase64);
      if (storedImageBytes.isEmpty) {
        throw Exception('La imagen almacenada está vacía');
      }
      final capturedImageBytes = await capturedImageFile.readAsBytes();
      if (capturedImageBytes.isEmpty) {
        throw Exception('La imagen capturada está vacía');
      }
      log('Tamaño imagen almacenada: ${storedImageBytes.length} bytes');
      log('Tamaño imagen capturada: ${capturedImageBytes.length} bytes');

      final storedFaceImage = MatchFacesImage(storedImageBytes, ImageType.PRINTED);
      final capturedFaceImage = MatchFacesImage(capturedImageBytes, ImageType.LIVE);

      final request = MatchFacesRequest([storedFaceImage, capturedFaceImage]);
      final response = await faceSdk.matchFaces(request);
      final split = await faceSdk.splitComparedFaces(response.results, 0.75);

      if (split.matchedFaces.isNotEmpty) {
        final similarity = split.matchedFaces[0].similarity;
        log('Similitud de comparación: $similarity');
        return similarity >= 0.80;
      }
      log('No se encontraron coincidencias');
      return false;
    } catch (e, stack) {
      log('Error en comparación facial: $e\n$stack');
      return false;
    }
  }

  void dispose() {
    if (cameraController.value.isInitialized) {
      cameraController.dispose();
      log('Controlador de cámara liberado');
    }
  }
}
