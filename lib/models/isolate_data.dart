import 'dart:isolate';
import 'package:camera/camera.dart';

class IsolateData {
  IsolateData(
    this.cameraImage,
    this.interpreterAddress,
    this.labels,
  );

  CameraImage? cameraImage;
  int? interpreterAddress;
  List<String>? labels;
  SendPort? responsePort;
}
