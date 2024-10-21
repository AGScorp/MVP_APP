import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/TranslateController.dart';

class SpeechToTextPage extends StatelessWidget {
  // เรียกใช้งาน SpeechController
  final SpeechController speechController = Get.put(SpeechController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech to Text with GetX'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  speechController.text.value,
                  style: TextStyle(fontSize: 24.0),
                ),
              )),
          SizedBox(height: 20),
          Obx(() => FloatingActionButton(
                onPressed: () {
                  speechController.listen();
                },
                child: Icon(
                  speechController.isListening.value
                      ? Icons.mic_off
                      : Icons.mic,
                ),
              )),
        ],
      ),
    );
  }
}
