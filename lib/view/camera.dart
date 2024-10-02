import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:mvp_app/view/showList.dart';
import '../controller/CameraController.dart';

class CameraPage extends StatelessWidget {
  final CameraAIController _controller = Get.put(CameraAIController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Object AI Detection'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Get.to(() => DetectionListPage());
            },
          ),
        ],
      ),
      body: GetBuilder<CameraAIController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Display camera preview
              Expanded(
                child: CameraPreview(controller.cameraController.value!),
              ),

              // Capture button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await controller.captureAndProcessImage();
                  },
                  child: Text('Capture Image'),
                ),
              ),

              // Display detection results
              controller.detectionList.isNotEmpty
                  ? Expanded(
                child: ListView.builder(
                  itemCount: controller.detectionList.length,
                  itemBuilder: (context, index) {
                    final detection = controller.detectionList[index];
                    return ListTile(
                      title: Text(detection.label),
                      leading: detection.imageData != null
                          ? Image.memory(detection.imageData!)
                          : Container(),
                    );
                  },
                ),
              )
                  : Center(
                child: Text(
                  'No objects detected',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
