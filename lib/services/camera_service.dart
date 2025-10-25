import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  late CameraController _cameraController;
  bool _isInitialized = false;

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();
    _isInitialized = true;
  }

  CameraController get controller => _cameraController;

  bool get isInitialized => _isInitialized;

  Future<void> dispose() async {
    if (_isInitialized) {
      await _cameraController.dispose();
      _isInitialized = false;
    }
  }
}


