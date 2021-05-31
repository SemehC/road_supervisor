import 'package:tflite/tflite.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

class SensorsPredictor {
  static late Interpreter? interpreter;

  static List<String> labels = ["Bad", "Average", "Good"];
  static initializePredictor() async {
    print("Initializing sensor predictor");
    try {
      // Create interpreter from asset.
      interpreter = await Interpreter.fromAsset("SensorsModel.tflite");
    } catch (e) {
      print('Error loading model: ' + e.toString());
    }
    print("Done sensor predictor");
  }

  static int predict(List<List<double>> input) {
    if (interpreter == null) {
      print("Still loading interpreter");
      return -1;
    } else {
      // print("predicting");
      var output = List.filled(1 * 3, 0).reshape([1, 3]);

      interpreter!.run(input, output);
      List<double> out = [output[0][0], output[0][1], output[0][2]];
      int prediction =
          out.indexOf(out.reduce((curr, next) => curr > next ? curr : next));
      return prediction;
    }
  }
}
