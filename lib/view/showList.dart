import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/CameraController.dart';

class DetectionListPage extends StatefulWidget {
  @override
  State<DetectionListPage> createState() => _DetectionListPageState();
}

class _DetectionListPageState extends State<DetectionListPage> {
  final CameraAIController _detectionController = Get.find<CameraAIController>();
 // เรียก controller


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detected Objects'),
      ),
      body: Obx(() {
        if (_detectionController.detectionList.isEmpty) { // Check against detectionList
          return Center(child: Text('No objects detected.'));
        }
        return ListView.builder(
          itemCount: _detectionController.detectionList.length, // Use detectionList
          itemBuilder: (context, index) {
            final detection = _detectionController.detectionList[index];
            return ListTile(
              leading: detection.imageData != null
                  ? Image.memory(detection.imageData!) // Display captured image from Uint8List
                  : null, // No image available
              title: Text(detection.label), // Show the label of the detected object
            );
          },
        );
      }),
    );
  }
}
