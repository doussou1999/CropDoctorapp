import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const CropDoctorApp());
}

class CropDoctorApp extends StatelessWidget {
  const CropDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropDoctor',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image; // To store the selected/taken image
  final ImagePicker _picker = ImagePicker();

  // Method to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      // Vous pouvez ajouter ici un message d'erreur pour l'utilisateur
    }
  }

  // Method to take a photo using the camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });
      }
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      // Vous pouvez ajouter ici un message d'erreur pour l'utilisateur
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Couleur de fond plus claire
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Vert foncé
              Color(0xFFF5F5F5), // Blanc cassé
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Logo et Slogan avec effet d'élévation
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/icrisat.png',
                            height: 100,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1B5E20),
                                  Color(0xFF2E7D32),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Crop health is Vital',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Titre et description
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ).createShader(bounds),
                    child: const Text(
                      'CropDoctor',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your companion in identifying and diagnosing crop health issues.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF424242),
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Boutons avec animation au survol
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAnimatedButton(
                        onPressed: _takePhoto,
                        icon: Icons.camera_alt_rounded,
                        label: 'TAKE PHOTO',
                        color: Color.fromARGB(255, 48, 124, 51),
                      ),
                      _buildAnimatedButton(
                        onPressed: _pickImageFromGallery,
                        icon: Icons.photo_library_rounded,
                        label: 'GALLERY',
                        color: Color(0xFFE65100),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Nouveau bouton History
                  _buildAnimatedButton(
                    onPressed: () {
                      // TODO: Implémenter la navigation vers l'historique
                    },
                    icon: Icons.history_rounded,
                    label: 'HISTORY OF ANALYSIS',
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 40),

                  // Affichage de l'image sélectionnée
                  if (_image != null)
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Selected Image',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _image!,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
