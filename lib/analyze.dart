import 'package:flutter/material.dart';

class AnalyzePage extends StatelessWidget {
  const AnalyzePage({super.key});

  @override
  Widget build(BuildContext context) {
    print("Analyse page opened");

    return Scaffold(
      appBar: AppBar(title: const Text("Analyse")),
      body: const Center(child: Text("Analyse en cours... ")),
    );
  }
}
