import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/attendance_service.dart';
import '../models/attendance_record.dart';
import '../utils/constants.dart';
import 'add_student_screen.dart';
import 'attendance_list_screen.dart';

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final AttendanceService _attendanceService = AttendanceService();
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions());

  String? _recognizedName;
  Face? _detectedFace;
  bool _isProcessing = false;
  DateTime? _lastRecognitionTime;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraService.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _isPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      if (mounted) {
        _cameraService.controller.resumePreview();
      }
    }
  }

  Future<void> _initializeServices() async {
    await _cameraService.initialize();
    await _faceService.initialize();
    if (mounted) setState(() {});
    _startFaceRecognition();
  }

  void _startFaceRecognition() async {
    while (mounted) {
      if (_cameraService.isInitialized && !_isProcessing && !_isPaused) {
        _processCameraFrame();
      }
      await Future.delayed(Duration(milliseconds: 1000));
    }
  }

  Future<void> _processCameraFrame() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final image = await _cameraService.controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty && mounted) {
        _detectedFace = faces.first;
        setState(() {});

        // Extract and process face
        try {
          final imageBytes = File(image.path).readAsBytesSync();
          final decodedImage = img.decodeImage(imageBytes);
          
          if (decodedImage != null) {
            // Crop face region before preprocessing
            final bbox = _detectedFace!.boundingBox;
            final x = bbox.left.clamp(0, decodedImage.width - 1).toInt();
            final y = bbox.top.clamp(0, decodedImage.height - 1).toInt();
            final w = bbox.width.clamp(1, decodedImage.width - x).toInt();
            final h = bbox.height.clamp(1, decodedImage.height - y).toInt();
            final cropped = img.copyCrop(decodedImage, x: x, y: y, width: w, height: h);

            final preprocessed = _faceService.preprocessImage(cropped);
            final embedding = _faceService.generateEmbedding(preprocessed);
            
            if (embedding == null) {
              if (mounted) {
                setState(() {
                  _recognizedName = 'MODEL ERROR';
                });
              }
              return;
            }
            
            final recognized = _faceService.recognizeFace(embedding);

            if (recognized != null && mounted) {
              // Mark attendance if not marked today
              final alreadyMarked = await _attendanceService.isStudentMarkedToday(recognized.name);
              
              if (!alreadyMarked) {
                final now = DateTime.now();
                final attendanceRecord = AttendanceRecord(
                  name: recognized.name,
                  date: now.toString().split(' ')[0],
                  time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                  status: 'Present',
                );
                await _attendanceService.insertAttendance(attendanceRecord);
                
                // Play beep sound and vibrate for new attendance
                HapticFeedback.heavyImpact();
                await SystemSound.play(SystemSoundType.alert);
                await Future.delayed(Duration(milliseconds: 200));
                HapticFeedback.heavyImpact();
                await SystemSound.play(SystemSoundType.alert);
              }

              setState(() {
                _recognizedName = recognized.name;
                _lastRecognitionTime = DateTime.now();
              });
            } else {
              setState(() {
                _recognizedName = null;
              });
            }
          }
        } catch (e) {
          print('Error in embedding generation: $e');
        }
      } else {
        setState(() {
          _recognizedName = null;
          _detectedFace = null;
        });
      }

      File(image.path).delete();
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _faceService.dispose();
    _faceDetector.close();
    super.dispose();
  }

  void _navigateToAddStudent() async {
    _isPaused = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddStudentScreen()),
    );
    
    if (mounted) {
      // Reinitialize camera if it was disposed by AddStudentScreen
      if (!_cameraService.isInitialized) {
        await _cameraService.initialize();
      }
      
      _isPaused = false;
      await _faceService.initialize();
      
      // Resume camera preview
      if (_cameraService.isInitialized) {
        await _cameraService.controller.resumePreview();
      }
      
      // Force UI rebuild to show camera
      setState(() {});
    }
  }

  void _navigateToAttendanceList() async {
    _isPaused = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttendanceListScreen()),
    );
    
    if (mounted) {
      _isPaused = false;
      if (_cameraService.isInitialized) {
        await _cameraService.controller.resumePreview();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraService.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Face Attendance App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 50),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              SizedBox(height: 15),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 80),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      'Developed By:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Abdul Haseeb (FA23-BCS-120)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraService.controller),
          if (_detectedFace != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return IgnorePointer(
                  child: CustomPaint(
                    painter: FaceOverlayPainter(
                      _detectedFace!,
                      isRecognized: _recognizedName != null,
                      imageSize: Size(
                        _cameraService.controller.value.previewSize!.height,
                        _cameraService.controller.value.previewSize!.width,
                      ),
                      screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
                );
              },
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _recognizedName == 'MODEL ERROR'
                    ? 'Replace facenet_model.tflite with actual model file'
                    : _recognizedName != null
                        ? '$_recognizedName - Present'
                        : 'Detecting face...',
                style: TextStyle(
                  color: _recognizedName == 'MODEL ERROR'
                      ? Colors.red
                      : _recognizedName != null
                          ? Colors.green
                          : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAttendanceList,
                    icon: Icon(Icons.list_alt, color: Colors.white),
                    label: Text(
                      'Attendance',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAddStudent,
                    icon: Icon(Icons.person_add, color: Colors.white),
                    label: Text(
                      'Add Student',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  final Face face;
  final bool isRecognized;
  final Size imageSize;
  final Size screenSize;

  FaceOverlayPainter(
    this.face, {
    this.isRecognized = false,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRecognized ? Colors.green : Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Calculate scale to transform from image coordinates to screen coordinates
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offset for centering
    final offsetX = (screenSize.width - imageSize.width * scale) / 2;
    final offsetY = (screenSize.height - imageSize.height * scale) / 2;

    final mirroredLeft = imageSize.width - face.boundingBox.left - face.boundingBox.width;

    final rect = Rect.fromLTWH(
      mirroredLeft * scale + offsetX,
      face.boundingBox.top * scale + offsetY,
      face.boundingBox.width * scale,
      face.boundingBox.height * scale,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) => true;
}
