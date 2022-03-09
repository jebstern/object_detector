import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:object_detector/models/recognition.dart';
import 'package:object_detector/models/stats.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Classifier {
  Classifier({Interpreter? interpreter, List<String>? labels}) {
    loadInterpreterFromAssets(interpreter: interpreter);
    loadLabelsFromAssets(labels: labels);
  }

  Interpreter? _interpreter;
  List<String>? _labels;
  static const String MODEL_FILE_NAME = 'detect.tflite';
  static const String LABEL_FILE_NAME = 'labelmap.txt';
  static const int INPUT_SIZE = 300;
  static const double THRESHOLD = 0.5;
  ImageProcessor? imageProcessor;
  int? padSize;
  List<List<int>>? _outputShapes;
  List<TfLiteType>? _outputTypes;
  static const int NUM_RESULTS = 10;

  Interpreter? get interpreter => _interpreter;
  List<String>? get labels => _labels;

  Future<void> loadInterpreterFromAssets({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            MODEL_FILE_NAME,
            options: InterpreterOptions()..threads = 4,
          );

      final List<Tensor> outputTensors = _interpreter!.getOutputTensors();
      _outputShapes = [];
      _outputTypes = [];
      for (final tensor in outputTensors) {
        _outputShapes!.add(tensor.shape);
        _outputTypes!.add(tensor.type);
      }
    } catch (e) {
      debugPrint('Error while creating interpreter: $e');
    }
  }

  Future<void> loadLabelsFromAssets({List<String>? labels}) async {
    try {
      _labels = labels ?? await FileUtil.loadLabels('assets/$LABEL_FILE_NAME');
    } catch (e) {
      debugPrint('Error while loading labels: $e');
    }
  }

  TensorImage getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);
    imageProcessor ??= ImageProcessorBuilder().add(ResizeWithCropOrPadOp(padSize ?? 1, padSize ?? 1)).add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR)).build();
    return imageProcessor!.process(inputImage);
  }

  Map<String, dynamic>? predictObjectsInImage(image_lib.Image image) {
    final predictStartTime = DateTime.now().millisecondsSinceEpoch;

    if (_interpreter == null) {
      debugPrint('Interpreter not initialized');
      return null;
    }

    final preProcessStart = DateTime.now().millisecondsSinceEpoch;
    TensorImage inputImage = TensorImage.fromImage(image);
    inputImage = getProcessedImage(inputImage);
    final preProcessElapsedTime = DateTime.now().millisecondsSinceEpoch - preProcessStart;
    final TensorBuffer outputLocations = TensorBufferFloat(_outputShapes![0]);
    final TensorBuffer outputClasses = TensorBufferFloat(_outputShapes![1]);
    final TensorBuffer outputScores = TensorBufferFloat(_outputShapes![2]);
    final TensorBuffer numLocations = TensorBufferFloat(_outputShapes![3]);
    final List<Object> inputs = [inputImage.buffer];
    final Map<int, Object> outputs = {
      0: outputLocations.buffer,
      1: outputClasses.buffer,
      2: outputScores.buffer,
      3: numLocations.buffer,
    };

    final inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;
    _interpreter!.runForMultipleInputs(inputs, outputs);
    final inferenceTimeElapsed = DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;
    final int resultsCount = min(NUM_RESULTS, numLocations.getIntValue(0));
    const int labelOffset = 1;
    final List<Rect> locations = BoundingBoxUtils.convert(
      tensor: outputLocations,
      valueIndex: [1, 0, 3, 2],
      boundingBoxAxis: 2,
      boundingBoxType: BoundingBoxType.BOUNDARIES,
      coordinateType: CoordinateType.RATIO,
      height: INPUT_SIZE,
      width: INPUT_SIZE,
    );

    final List<Recognition> recognitions = [];

    for (int i = 0; i < resultsCount; i++) {
      final score = outputScores.getDoubleValue(i);
      final labelIndex = outputClasses.getIntValue(i) + labelOffset;
      final label = _labels!.elementAt(labelIndex);

      if (score > THRESHOLD) {
        final Rect transformedRect = imageProcessor!.inverseTransformRect(locations[i], image.height, image.width);
        recognitions.add(Recognition(i, label, score, transformedRect));
      }
    }

    final predictElapsedTime = DateTime.now().millisecondsSinceEpoch - predictStartTime;

    return {
      'recognitions': recognitions,
      'stats': Stats(
        totalPredictTime: predictElapsedTime,
        inferenceTime: inferenceTimeElapsed,
        preProcessingTime: preProcessElapsedTime,
        totalElapsedTime: 0,
      )
    };
  }
}
