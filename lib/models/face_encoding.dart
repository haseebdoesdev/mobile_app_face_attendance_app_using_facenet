class FaceEncoding {
  final String name;
  final List<double> embedding;

  FaceEncoding({
    required this.name,
    required this.embedding,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'embedding': embedding,
    };
  }

  factory FaceEncoding.fromJson(Map<String, dynamic> json) {
    return FaceEncoding(
      name: json['name'],
      embedding: List<double>.from(json['embedding']),
    );
  }
}

