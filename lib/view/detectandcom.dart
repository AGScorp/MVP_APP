import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mvp_app/controller/detectionController.dart';
import 'package:mvp_app/view/showList.dart';

class CompareAndDetect extends StatelessWidget {
  const CompareAndDetect({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CompareAndDetect AI Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Get.to(() => DetectionListPage());
            },
          ),
        ],
      ),
      body: GetBuilder<ComAndDetectController>(
        init: ComAndDetectController(), // Ensure the controller is initialized
        builder: (controller) {
          // Display loading indicator while image is being processed
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Display camera preview
              Expanded(
                child: Row(
                  children: [
                    CameraPreview(controller.cameraController.value!),
                    controller.detectionList.isNotEmpty  ?  GestureDetector(
                      onTap: controller.pickImage, // เมื่อกดเลือกภาพ
                      child: Container(
                        height: Get.height,
                        width: Get.width * 0.5,
                        color: Colors.red,
                        child: controller.image != null
                            ? Image.file(
                          controller.image!, // แสดงภาพที่เลือก
                          fit: BoxFit.cover,
                        )
                            : Center(
                          child: Text(
                            'Tap to select image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ) : Container()
                  ],
                ),
              ),

              Center(child: Text("${controller.detectionList.length}")),
              // Capture button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween ,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await controller.captureAndProcessImage();
                      },
                      child: const Text('Capture Image'),
                    ),

                  ],
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // เพิ่ม padding
                      title: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ส่วนซ้าย
                              Expanded(
                                flex: 2, // ปรับขนาดให้เหมาะสม
                                child:ListTile(
                                  title: Text(detection.label),
                                  leading:detection.imageData != null
                                      ? Image.memory(detection.imageData)
                                      : Container(height: 1,width: 1,color: Colors.white),
                                  subtitle: Text("Accuracy: ${detection.accuracy != null ? detection.accuracy!.toStringAsFixed(2) : '0.00'}%"),
                                )
                              ),

                              // ส่วนขวา
                              Expanded(
                                flex: 1,
                                child:ListTile(
                                  leading:controller.croppedFaceImage != null
                                      ? Image.memory(controller.croppedFaceImage!)
                                      : Container(height: 1,width: 1,color: Colors.white,
                                  ) ,
                                )
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await controller.compareFaces(detection.imageData,controller.croppedFaceImage!);
                            },
                            child: const Text('Calculate'),
                          ),
                        ],
                      ),
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
