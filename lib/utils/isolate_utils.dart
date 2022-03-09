import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as image_lib;
import 'package:object_detector/models/classifier.dart';
import 'package:object_detector/models/isolate_data.dart';
import 'package:object_detector/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateUtils {
  static const String DEBUG_NAME = 'InferenceIsolate';
  final ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    _sendPort = await _receivePort.first;
  }

  static Future<void> entryPoint(SendPort sendPort) async {
    final ReceivePort port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData isolateData in port) {
      if (isolateData.interpreterAddress != null && isolateData.cameraImage != null && isolateData.responsePort != null) {
        final Classifier classifier = Classifier(interpreter: Interpreter.fromAddress(isolateData.interpreterAddress!), labels: isolateData.labels);
        image_lib.Image? image = convertCameraImage(isolateData.cameraImage!);
        if (Platform.isAndroid) {
          image = image_lib.copyRotate(image!, 90);
        }
        final Map<String, dynamic>? results = classifier.predictObjectsInImage(image!);
        isolateData.responsePort!.send(results);
      }
    }
  }
}
