import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/face_encoding.dart';
import '../utils/constants.dart';

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  Interpreter? _interpreter;
  List<FaceEncoding> _faceEncodings = [];
  bool _isInitialized = false;
  bool _modelLoadFailed = false;

  factory FaceRecognitionService() {
    return _instance;
  }

  FaceRecognitionService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(Constants.faceModelPath);
      await _loadEncodings();
      _isInitialized = true;
      print('FaceNet model loaded successfully');
    } catch (e) {
      _modelLoadFailed = true;
      print('ERROR: Failed to load FaceNet model: $e');
      print('Please replace assets/models/facenet_model.tflite with actual model file');
    }
  }

  Future<void> _loadEncodings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${Constants.encodingsFile}');
      
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);
        final List<dynamic> encodingsList = jsonData['encodings'] ?? [];
        final List<dynamic> namesList = jsonData['names'] ?? [];

        _faceEncodings.clear();
        for (int i = 0; i < encodingsList.length; i++) {
          _faceEncodings.add(FaceEncoding(
            name: namesList[i],
            embedding: List<double>.from(encodingsList[i]),
          ));
        }
      }
    } catch (e) {
      print('Error loading encodings: $e');
    }
  }

  List<double>? generateEmbedding(List<List<List<num>>> imageData) {
    if (_interpreter == null || _modelLoadFailed) return null;
    
    // Wrap in batch dimension: [1, 160, 160, 3]
    final inputWithBatch = [imageData];
    
    var output = List<double>.filled(Constants.faceEmbeddingSize, 0.0);
    List<List<double>> reshapedOutput = [output];
    _interpreter!.run(inputWithBatch, reshapedOutput);
    return reshapedOutput.first;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = normA > 0 ? math.sqrt(normA) : 1;
    normB = normB > 0 ? math.sqrt(normB) : 1;

    return dotProduct / (normA * normB);
  }

  FaceEncoding? recognizeFace(List<double> embedding) {
    FaceEncoding? best;
    double maxSimilarity = Constants.faceRecognitionThreshold;

    for (var encoding in _faceEncodings) {
      double similarity = cosineSimilarity(embedding, encoding.embedding);
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
        best = encoding;
      }
    }

    return best;
  }

  Future<void> enrollStudent(String name, List<List<List<List<num>>>> photoImages) async {
    if (_interpreter == null || _modelLoadFailed) {
      throw Exception('Model not loaded. Cannot enroll student.');
    }
    
    List<List<double>> embeddings = [];
    
    for (var imageData in photoImages) {
      List<double>? embedding = generateEmbedding(imageData);
      if (embedding != null) {
        embeddings.add(embedding);
      }
    }

    if (embeddings.isEmpty) {
      throw Exception('Failed to generate embeddings');
    }

    // Average all embeddings
    List<double> avgEmbedding = List.filled(Constants.faceEmbeddingSize, 0.0);
    for (var embedding in embeddings) {
      for (int i = 0; i < embedding.length; i++) {
        avgEmbedding[i] += embedding[i];
      }
    }
    for (int i = 0; i < avgEmbedding.length; i++) {
      avgEmbedding[i] /= embeddings.length;
    }

    _faceEncodings.add(FaceEncoding(name: name, embedding: avgEmbedding));
    await _saveEncodings();
  }

  Future<void> _saveEncodings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${Constants.encodingsFile}');

      final encodings = _faceEncodings.map((e) => e.embedding).toList();
      final names = _faceEncodings.map((e) => e.name).toList();

      final jsonData = {
        'encodings': encodings,
        'names': names,
      };

      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      print('Error saving encodings: $e');
    }
  }

  List<List<List<num>>> preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: Constants.faceInputSize,
      height: Constants.faceInputSize,
    );

    final input = List<List<List<num>>>.generate(
      Constants.faceInputSize,
      (y) => List<List<num>>.generate(
        Constants.faceInputSize,
        (x) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          return [r, g, b];
        },
      ),
    );

    return input;
  }

  void dispose() {
    _interpreter?.close();
  }
}
