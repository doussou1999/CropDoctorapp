import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For compute()
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'db_helper.dart';

class AnalyzePage extends StatefulWidget {
  final File imageFile;
  final int? userId;

  const AnalyzePage({super.key, required this.imageFile, this.userId});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  String _result = "Analyse en cours...";
  String _progress = "";
  String _recommendation = "";
  bool _isLoading = true;
  bool _gettingRecommendation = false;
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
      // Display results immediately after loading labels
      setState(() {
        _result = "Ready for analysis...";
        _isLoading = false;
      });

      // Start heavy processing using compute()
      final result = await compute(_runInference, {
        'imagePath': widget.imageFile.path,
        'labels': _labels,
        'inputSize': inputSize,
        'interpreter': _interpreter,
      });

      // Parse the result to extract class and confidence
      final resultParts = result['result'].split('\n');
      final predictedClass = resultParts[0].replaceFirst(
        'Predicted class: ',
        '',
      );
      final confidence =
          resultParts.length > 1
              ? resultParts[1].replaceFirst('Confidence: ', '')
              : 'N/A';

      setState(() {
        _result = "Classe: $predictedClass\nConfiance: $confidence";
        _isLoading = false;
        _processing = false;
      });

      // Save analysis result to database if user is logged in
      if (widget.userId != null) {
        final dbHelper = DBHelper();
        final now = DateTime.now().toIso8601String();
        await dbHelper.insertAnalysis(
          widget.userId!,
          widget.imageFile.path,
          _result,
          now,
        );
      }

      _getRecommendation(predictedClass);
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

  Future<void> _getRecommendation(String predictedClass) async {
    setState(() {
      _gettingRecommendation = true;
    });

    try {
      // Charger la clé API depuis .env
      await dotenv.load();

      try {
        final model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: dotenv.env['GEMINI_API_KEY']!,
        );

        final prompt = """
        As an expert in groundnut cultivation, provide 3–5 concise treatment recommendations for the identified condition: $predictedClass. This application is designed to assist groundnut farmers; all classes pertain to diseases affecting groundnut plants, except for the 'healthy' class, which indicates a healthy plant. Present the recommendations as clear bullet points, each accompanied by relevant emojis.
        """;

        final response = await model.generateContent([Content.text(prompt)]);

        setState(() {
          _recommendation =
              response.text?.replaceAll('•', '➤') ??
              "Aucune recommandation disponible";
        });
      } catch (e) {
        setState(() {
          _recommendation = "Erreur API: ${e.toString()}";
        });
      }
    } catch (e) {
      setState(() {
        _recommendation = "Erreur lors de la récupération des recommandations";
      });
    } finally {
      setState(() {
        _gettingRecommendation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analysis Result",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_processing)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(widget.imageFile, fit: BoxFit.contain),
                  ),
                ),
              const SizedBox(height: 30),
              if (_isLoading) ...[
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _progress,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else
                Column(
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "Recommandations:",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _gettingRecommendation
                                ? CircularProgressIndicator()
                                : SizedBox(
                                  height: 300,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _recommendation,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
