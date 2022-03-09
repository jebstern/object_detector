/// Bundles different elapsed times
class Stats {
  Stats({
    required this.totalPredictTime,
    required this.totalElapsedTime,
    required this.inferenceTime,
    required this.preProcessingTime,
  });

  int totalPredictTime;
  int totalElapsedTime;
  int inferenceTime;
  int preProcessingTime;

  @override
  String toString() {
    return 'Stats{totalPredictTime: $totalPredictTime, totalElapsedTime: $totalElapsedTime, inferenceTime: $inferenceTime, preProcessingTime: $preProcessingTime}';
  }
}
