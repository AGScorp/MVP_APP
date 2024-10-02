import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mvp_app/view/showList.dart';
import '../controller/faceComController.dart';

class Facecompaer_view extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face AI Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Get.to(() => DetectionListPage());
            },
          ),
        ],
      ),
      body: GetBuilder<FaceComController>(
        init: FaceComController(), // Ensure the controller is initialized
        builder: (controller) {
          // Display loading indicator while image is being processed
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Display camera preview
              Expanded(
                child: CameraPreview(controller.cameraController.value!),
              ),
              Center(child: Text("${controller.detectionList.length}")),
              // Capture button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await controller.captureAndProcessImage();
                  },
                  child: const Text('Capture Image'),
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
                                ? Image.memory(detection.imageData)
                                : Container(),
                          );
                        },
                      ),
                    )
                  : const Center(
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
