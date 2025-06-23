# CropDoctor

CropDoctor is a Flutter mobile application designed to assist farmers and agricultural professionals in identifying and diagnosing crop health issues using machine learning and artificial intelligence technologies.

## Features

- User registration and login with local database authentication
- Capture photos or select images from the gallery for analysis
- Image classification using a TensorFlow Lite model to detect crop diseases
- AI-generated treatment recommendations powered by Google Generative AI
- View history of past analyses with images, results, and dates

## Getting Started

### Prerequisites

- Flutter SDK installed (version compatible with Dart SDK ^3.7.2)
- A device or emulator to run the Flutter app

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/doussou1999/t1.git
   cd t1
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

## Usage

- Register a new account or log in with existing credentials.
- Use the camera to take a photo of a crop or select an image from the gallery.
- Analyze the image to receive a diagnosis and treatment recommendations.
- View your history of analyses to track past results.

## Technologies Used

- Flutter for cross-platform mobile development
- TensorFlow Lite for on-device machine learning inference
- SQLite (sqflite) for local data storage
- Google Generative AI for treatment recommendations
- Image Picker for image selection and capture

## Assets

- Pre-trained TensorFlow Lite model (`assets/vgg16_model.tflite`)
- Labels file for classification (`assets/labels.txt`)
- App logo (`assets/images/icrisat.png`)

## Environment Variables

The app uses environment variables to manage API keys securely. Create a `.env` file in the project root with the following content:

```
GEMINI_API_KEY=your_google_generative_ai_api_key_here
```

## Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
