// ignore_for_file: prefer_mixin
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:object_detector/models/camera_view_singleton.dart';
import 'package:object_detector/models/classifier.dart';
import 'package:object_detector/models/isolate_data.dart';
import 'package:object_detector/models/recognition.dart';
import 'package:object_detector/models/stats.dart';
import 'package:object_detector/utils/isolate_utils.dart';

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.resultsCallback,
    required this.statsCallback,
  }) : super(key: key);

  final Function(List<Recognition> recognitions) resultsCallback;
  final Function(Stats stats) statsCallback;

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool? predicting;
  Classifier? _classifier;
  IsolateUtils? _isolateUtils;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  Future<void> initStateAsync() async {
    WidgetsBinding.instance!.addObserver(this);
    _isolateUtils = IsolateUtils();
    await _isolateUtils!.start();
    await initializeCamera();
    _classifier = Classifier();
    predicting = false;
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras![0], ResolutionPreset.ultraHigh, enableAudio: false);
    await _cameraController!.initialize();
    await _cameraController!.startImageStream(onLatestImageAvailable);

    final Size? previewSize = _cameraController!.value.previewSize;
    CameraViewSingleton.inputImageSize = previewSize!;
    final Size screenSize = MediaQuery.of(context).size;
    CameraViewSingleton.screenSize = screenSize;
    CameraViewSingleton.ratio = screenSize.width / previewSize.height;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(color: Colors.deepOrange);
    }
    return CameraPreview(_cameraController!);
  }

  Future<void> onLatestImageAvailable(CameraImage cameraImage) async {
    if (_classifier == null) {
      return;
    }
    if (_classifier!.interpreter != null && _classifier!.labels != null) {
      if (predicting != null && predicting!) {
        return;
      }

      setState(() {
        predicting = true;
      });

      final uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;
      final isolateData = IsolateData(cameraImage, _classifier!.interpreter!.address, _classifier!.labels!);
      final Map<String, dynamic> inferenceResults = await inference(isolateData);
      final uiThreadInferenceElapsedTime = DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;
      widget.resultsCallback(inferenceResults['recognitions']);
      widget.statsCallback((inferenceResults['stats'] as Stats)..totalElapsedTime = uiThreadInferenceElapsedTime);

      setState(() {
        predicting = false;
      });
    }
  }

  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    final ReceivePort responsePort = ReceivePort();
    _isolateUtils!.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    final results = await responsePort.first;
    return results;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        await _cameraController?.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (_cameraController != null) {
          if (!_cameraController!.value.isStreamingImages) {
            await _cameraController!.startImageStream(onLatestImageAvailable);
          }
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    super.dispose();
  }
}
