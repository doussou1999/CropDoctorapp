import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For compute()
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AnalyzePage extends StatefulWidget {
  final File imageFile;

  const AnalyzePage({super.key, required this.imageFile});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  String _result = "Analyse en cours...";
  String _progress = "";
  bool _isLoading = true;
  late Interpreter _interpreter;
  List<String> _labels = [];
  bool _processing = false;

  final int inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModelAndClassify();
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  Future<void> _loadModelAndClassify() async {
    setState(() {
      _isLoading = true;
      _processing = true;
    });

    try {
      // Load model in main isolate
      _updateProgress('Loading TensorFlow Lite model...');
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/vgg16_model.tflite',
        options: options,
      );
      _updateProgress('Model loaded successfully');

      // Load labels
      _updateProgress('Loading labels...');
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n');
      _updateProgress('Loaded ${_labels.length} labels');

      // Start heavy processing using compute()
      final result = await compute(_runInference, {
        'imagePath': widget.imageFile.path,
        'labels': _labels,
        'inputSize': inputSize,
        'interpreter': _interpreter,
      });

      setState(() {
        _result = result['result'];
        _isLoading = false;
        _processing = false;
      });
    } catch (e) {
      _updateProgress('Error: $e');
      setState(() {
        _result = "Erreur lors de l'analyse : $e";
        _isLoading = false;
        _processing = false;
      });
    }
  }

  void _updateProgress(String message) {
    setState(() {
      _progress = message;
    });
  }

  // Compute function for background processing
  static Map<String, dynamic> _runInference(Map<String, dynamic> args) {
    final imagePath = args['imagePath'] as String;
    final labels = args['labels'] as List<String>;
    final inputSize = args['inputSize'] as int;
    final interpreter = args['interpreter'] as Interpreter;

    try {
      // Load and process image
      final imageBytes = File(imagePath).readAsBytesSync();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Preprocess image to match Python implementation
      final input = List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => List<double>.filled(3, 0.0),
          growable: false,
        ),
        growable: false,
      );

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          // Normalize to [0,1] range as in Python code
          input[y][x][0] = img.getRed(pixel) / 255.0; // R
          input[y][x][1] = img.getGreen(pixel) / 255.0; // G
          input[y][x][2] = img.getBlue(pixel) / 255.0; // B
        }
      }

      // Get input/output tensor details with explicit typing
      final inputTensor = (input as List<List<List<double>>>).reshape([
        1,
        inputSize,
        inputSize,
        3,
      ]);
      final outputTensor = List<double>.filled(
        labels.length,
        0.0,
      ).reshape([1, labels.length]);

      // Run inference
      interpreter.run(inputTensor, outputTensor);

      // Process results
      final probs = List<double>.from(outputTensor[0]);
      final maxIndex = probs.indexWhere(
        (val) => val == probs.reduce((double a, double b) => a > b ? a : b),
      );
      final maxConfidence = probs[maxIndex];
      final predictedLabel = labels[maxIndex];
      final confidence = (maxConfidence * 100).toStringAsFixed(2);

      return {
        'result':
            maxConfidence < 0.5
                ? 'No object detected (confidence: $confidence%)'
                : 'Predicted class: $predictedLabel\nConfidence: $confidence%',
      };
    } catch (e) {
      return {'result': 'Error: $e'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Résultat de l'analyse")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_processing)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Image.file(widget.imageFile, fit: BoxFit.contain),
              ),
            const SizedBox(height: 30),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _progress,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ] else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
