class FacePosition {
  final double h;
  final List<double> leftEye;
  final List<double> rightEye;
  final double w;
  final double x;
  final double y;

  FacePosition({
    required this.h,
    required this.leftEye,
    required this.rightEye,
    required this.w,
    required this.x,
    required this.y,
  });

  factory FacePosition.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Handle null JSON by throwing an error or returning a default instance
      throw Exception('Invalid JSON for FacePosition');
    }
    return FacePosition(
      h: json['h']?.toDouble() ?? 0.0,
      leftEye: List<double>.from(json['left_eye'] ?? []),
      rightEye: List<double>.from(json['right_eye'] ?? []),
      w: json['w']?.toDouble() ?? 0.0,
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
    );
  }
}

class FaceDetection {
  final FacePosition facePosition;
  final String gender;

  FaceDetection({
    required this.facePosition,
    required this.gender,
  });

  factory FaceDetection.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Handle null JSON by throwing an error or returning a default instance
      throw Exception('Invalid JSON for FaceDetection');
    }
    return FaceDetection(
      facePosition: FacePosition.fromJson(json['face_position']),
      gender: json['gender'] ?? '',
    );
  }
}
