import 'package:flutter/material.dart';
import 'package:mvp_app/view/FaceLiveness.dart';
import 'package:mvp_app/view/camera.dart';
import 'package:mvp_app/view/detectandcom.dart';
import 'package:mvp_app/view/facecompaer.dart';
import 'package:mvp_app/view/filePicker.dart';
import 'package:mvp_app/view/showList.dart';
import 'package:mvp_app/view/test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'blinding.dart';
import 'controller/controller.dart';
import 'package:get/get.dart';

Future<void> main() async {
  await SentryFlutter.init(
        (options) {
      options.dsn = 'https://a9417f9e0ddfe965d6d5a031204155cd@o4508045087408128.ingest.us.sentry.io/4508045102022656';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(MyApp()),
  );

  // or define SENTRY_DSN via Dart environment variable (--dart-define)
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      initialBinding: CounterBinding(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MVP APP'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // Instantiate the controller
    final CounterController counterController = Get.put(CounterController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Get.to(FilePickerPage());
                },
                child: Text('File Picker')),
            ElevatedButton(
                onPressed: () {
                  Get.to(() => CameraPage());
                },
                child: Text('Object Detect')),
            ElevatedButton(
                onPressed: () {
                  Get.to(() => Facecompaer_view());
                },
                child: Text('Face Detect')),
            ElevatedButton(
                onPressed: () {
                  Get.to(() => DetectionListPage());
                },
                child: Text('DetectionListPage')),
            ElevatedButton(
                onPressed: () {
                  Get.to(() => CompareAndDetect());
                },
                child: Text('CompareAndDetect'))
            , ElevatedButton(
                onPressed: () {
                  Get.to(() => FaceLiveness());
                },
                child: Text('Face Liveness \n need API'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: counterController.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
