class EmotionValue {
  final double angry;
  final double disgust;
  final double fear;
  final double happy;
  final double neutral;
  final double sad;
  final double surprise;

  EmotionValue({
    required this.angry,
    required this.disgust,
    required this.fear,
    required this.happy,
    required this.neutral,
    required this.sad,
    required this.surprise,
  });

  factory EmotionValue.fromJson(Map<String, dynamic> json) {
    return EmotionValue(
      angry: json['angry'],
      disgust: json['disgust'],
      fear: json['fear'],
      happy: json['happy'],
      neutral: json['neutral'],
      sad: json['sad'],
      surprise: json['surprise'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'angry': angry,
      'disgust': disgust,
      'fear': fear,
      'happy': happy,
      'neutral': neutral,
      'sad': sad,
      'surprise': surprise,
    };
  }
}


class FacePosition {
  final double x;
  final double y;
  final double w;
  final double h;

  FacePosition({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  factory FacePosition.fromJson(Map<String, dynamic> json) {
    return FacePosition(
      x: json['x'],
      y: json['y'],
      w: json['w'],
      h: json['h'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'w': w,
      'h': h,
    };
  }
}


class FaceData {
  final int age;
  final String emotion;
  final String gender;
  final FacePosition facePosition;

  FaceData({
    required this.age,
    required this.emotion,
    required this.gender,
    required this.facePosition,
  });

  factory FaceData.fromJson(Map<String, dynamic> json) {
    return FaceData(
      age: json['age'],
      emotion: json['emotion'],
      gender: json['gender'],
      facePosition: FacePosition.fromJson(json['face_position']),
    );
  }
}
