import 'dart:typed_data';

class DetectionItem {
  final String label;
  final Uint8List imageData;
   double? accuracy;

  DetectionItem({required this.label, required this.imageData , this.accuracy});
}
