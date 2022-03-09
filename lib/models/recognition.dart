import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:object_detector/models/camera_view_singleton.dart';

/// Represents the recognition output from the model
class Recognition {
  Recognition(this._id, this._label, this._score, [this._location]);

  final int _id;
  final String _label;
  final double _score;
  final Rect? _location;

  int get id => _id;
  String get label => _label;
  String get score => '${(_score * 100).toStringAsFixed(0)}%';
  Rect get location => _location!;

  Rect get renderLocation {
    final double ratioX = CameraViewSingleton.ratio;
    final double ratioY = ratioX;
    final double transLeft = max(0.1, location.left * ratioX);
    final double transTop = max(0.1, location.top * ratioY);
    final double transWidth = min(location.width * ratioX, CameraViewSingleton.actualPreviewSize.width);
    final double transHeight = min(location.height * ratioY, CameraViewSingleton.actualPreviewSize.height);
    final Rect transformedRect = Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
    return transformedRect;
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
