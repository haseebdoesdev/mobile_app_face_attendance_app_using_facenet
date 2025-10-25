class Constants {
  static const double faceRecognitionThreshold = 0.6;
  static const int photoCountForEnrollment = 10;
  static const String faceModelPath = 'assets/models/facenet_model.tflite';
  static const String encodingsFile = 'encodings.json';
  static const int faceInputSize = 160;
  static const int faceEmbeddingSize = 512;
}
