import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'upload_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
    ),
  );
  
  runApp(const WeddingApp());
}

class WeddingApp extends StatelessWidget {
  const WeddingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bizim Düğün Anıları',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Senin o sevdiğin şık gül kurusu / rose-colored paletimiz 🤍
        primaryColor: const Color(ColorList.roseGold),
        scaffoldBackgroundColor: const Color(0xFFFBF8F6),
        useMaterial3: true,
      ),
      home: const MemoryUploadScreen(),
    );
  }
}

class MemoryUploadScreen extends StatefulWidget {
  const MemoryUploadScreen({super.key});

  @override
  State<MemoryUploadScreen> createState() => _MemoryUploadScreenState();
}

class _MemoryUploadScreenState extends State<MemoryUploadScreen> {
  final UploadService _uploadService = UploadService();
  double _currentProgress = 0.0;
  bool _isUploading = false;
  String _statusMessage = "Düğünümüzden en güzel kareleri ve videoları bizimle paylaşın! 🤍";

  void _startUploadProcess() async {
    setState(() {
      _isUploading = true;
      _currentProgress = 0.0;
      _statusMessage = "Medya yükleniyor, lütfen sekmeyi kapatmayın...";
    });

    await _uploadService.pickAndUploadAni(
      onProgress: (progress) {
        setState(() {
          _currentProgress = progress;
        });
      },
      onSuccess: (message) {
        setState(() {
          _isUploading = false;
          _currentProgress = 0.0;
          _statusMessage = message;
        });
      },
      onError: (errorMessage) {
        setState(() {
          _isUploading = false;
          _currentProgress = 0.0;
          _statusMessage = errorMessage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Şık Üst Başlık ve İkon
              Icon(
                Icons.favorite_rounded,
                color: Color(ColorList.roseGold),
                size: 72,
              ),
              const SizedBox(height: 16),
              const Text(
                "Anılarımıza Ortak Olun",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(HeaderColor.darkText),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Dinamik Durum Mesajı
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Yükleme Durumuna Göre Değişen Progress Bar veya Buton
              if (_isUploading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _currentProgress / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(ColorList.roseGold)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "%${_currentProgress.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(ColorList.roseGold),
                  ),
                ),
              ] else ...[
                // Şık Yükleme Butonu
                ElevatedButton.icon(
                  onPressed: _startUploadProcess,
                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                  label: const Text(
                    "Fotoğraf / Video Yükle",
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(ColorList.roseGold),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Renk kodlarımızı temiz tutmak için küçük yardımcı sınıflar
class ColorList {
  static const int roseGold = 0xFFB76E79; // Gül Kurusu rengimiz
}
class HeaderColor {
  static const int darkText = 0xFF4A3E3D;
}