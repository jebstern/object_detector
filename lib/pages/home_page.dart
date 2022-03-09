// ignore_for_file: comment_references
import 'package:flutter/material.dart';
import 'package:object_detector/models/camera_view_singleton.dart';
import 'package:object_detector/models/recognition.dart';
import 'package:object_detector/models/stats.dart';
import 'package:object_detector/widgets/box_widget.dart';
import 'package:object_detector/widgets/camera_view.dart';
import 'package:object_detector/widgets/stats_row_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  List<Recognition>? _results;
  Stats? stats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Object detector'),
      ),
      body: Container(
        color: Theme.of(context).primaryColor,
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            CameraView(
              resultsCallback: resultsCallback,
              statsCallback: statsCallback,
            ),
            if (_results == null)
              const Center(child: Text('No results yet, waiting for data...'))
            else
              Stack(
                children: _results!.map((e) => BoxWidget(result: e)).toList(),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                initialChildSize: 0.05,
                minChildSize: 0.05,
                maxChildSize: 0.3,
                builder: (_, ScrollController scrollController) {
                  return Container(
                    width: double.maxFinite,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: stats == null
                            ? Container()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatsRow(left: 'Inference time:', right: '${stats!.inferenceTime} ms'),
                                  StatsRow(left: 'Total prediction time:', right: '${stats!.totalElapsedTime} ms'),
                                  StatsRow(left: 'Pre-processing time:', right: '${stats!.preProcessingTime} ms'),
                                  StatsRow(left: 'Frame', right: '${CameraViewSingleton.inputImageSize.width} X ${CameraViewSingleton.inputImageSize.height}'),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void resultsCallback(List<Recognition> results) {
    setState(() {
      _results = results;
    });
  }

  void statsCallback(Stats stats) {
    setState(() {
      this.stats = stats;
    });
  }
}
