import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../utils/constants.dart';

class AddStudentScreen extends StatefulWidget {
  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final CameraService _cameraService = CameraService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions());

  int _photoCount = 0;
  bool _isCapturing = false;
  List<List<List<List<num>>>> _capturedPhotos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraService.isInitialized || _isCapturing) return;

    if (state == AppLifecycleState.resumed && mounted) {
      _cameraService.controller.resumePreview();
    }
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    await _faceService.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _capturePhotos() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter student name')),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
      _photoCount = 0;
      _capturedPhotos.clear();
    });

    // Wait for camera to stabilize
    await Future.delayed(Duration(milliseconds: 800));

    for (int i = 0; i < Constants.photoCountForEnrollment; i++) {
      if (!mounted) break;

      try {
        final image = await _cameraService.controller.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          // Load image and preprocess
          final imageBytes = File(image.path).readAsBytesSync();
          final decodedImage = img.decodeImage(imageBytes);
          
          if (decodedImage != null) {
            // Crop first detected face before preprocessing
            final bbox = faces.first.boundingBox;
            final x = bbox.left.clamp(0, decodedImage.width - 1).toInt();
            final y = bbox.top.clamp(0, decodedImage.height - 1).toInt();
            final w = bbox.width.clamp(1, decodedImage.width - x).toInt();
            final h = bbox.height.clamp(1, decodedImage.height - y).toInt();
            final cropped = img.copyCrop(decodedImage, x: x, y: y, width: w, height: h);

            final preprocessed = _faceService.preprocessImage(cropped);
            _capturedPhotos.add(preprocessed);
          }
        }

        setState(() {
          _photoCount = _capturedPhotos.length;
        });
      } catch (e) {
        print('Error capturing photo: $e');
      }
      
      // Wait between captures to avoid camera busy error
      await Future.delayed(Duration(milliseconds: 1000));
    }

    if (mounted && _capturedPhotos.isNotEmpty) {
      await _enrollStudent();
    } else {
      setState(() {
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photos')),
      );
    }
  }

  Future<void> _enrollStudent() async {
    try {
      await _faceService.enrollStudent(_nameController.text, _capturedPhotos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student enrolled successfully!')),
        );

        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error enrolling student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enrolling student')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    // Don't dispose shared camera service - main screen still needs it
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraService.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Add Student')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Student'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: _isCapturing
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cameraService.controller),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Capturing Photos...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${_photoCount}/${Constants.photoCountForEnrollment}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_photoCount == Constants.photoCountForEnrollment)
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(width: 16),
                                  Text(
                                    'Enrolling student...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Student Name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(16),
                          hintText: 'Enter full name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                      SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _capturePhotos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Capture ${Constants.photoCountForEnrollment} Photos',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Will capture ${Constants.photoCountForEnrollment} photos automatically (~${Constants.photoCountForEnrollment} seconds)',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
