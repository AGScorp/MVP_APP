import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/FaceLivenessController.dart';

class FaceLiveness extends StatelessWidget {
  FaceLiveness({super.key});

  final FaceLivenessController controller = Get.put(FaceLivenessController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Liveness Detection'),
      ),
      body: GetBuilder<FaceLivenessController>(
        builder: (_) {
          // Check if camera is initialized
          if (controller.cameraController.value == null ||
              !controller.cameraController.value!.value.isInitialized) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Stack(
                children: [
                  CameraPreview(controller.cameraController.value!),
                  _buildOverlay(),
                  if (!controller.isProcessing.value) // Check processing state
                    Positioned(
                      bottom: 29,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            backgroundColor: Colors.blueAccent, // Button color
                          ),
                          onPressed: controller.startLivenessCheck,
                          child: Text('Start Liveness Check'),
                        ),
                      ),
                    ),
                ],
              ),
          ElevatedButton(
          style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          backgroundColor: Colors.grey, // Button color
          ),
          onPressed:() async { await controller.sendImageToUnlock(context);} ,
          child: Text('Liveness Check \n  (Not Done)'),
          ),
            ],
          );

        },
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: GetBuilder<FaceLivenessController>(
        builder: (_) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.instruction.value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Follow the instructions to prove you are a real person.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              if (controller.livenessResult.isLivenessPassed)
                Text(
                  'Liveness Passed with ${controller.livenessResult.accuracy * 100}% accuracy',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!controller.livenessResult.isLivenessPassed && controller.isProcessing.value)
                Text(
                  'Liveness Check Failed. Please try again.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
