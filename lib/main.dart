import 'package:flutter/material.dart';
import 'upload_service.dart'; // Yazdığımız yükleme servisini bağlıyoruz

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hilal & Oğuz Düğün Anıları',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const WeddingUploadPage(),
    );
  }
}

class WeddingUploadPage extends StatefulWidget {
  const WeddingUploadPage({super.key});

  @override
  State<WeddingUploadPage> createState() => _WeddingUploadPageState();
}

class _WeddingUploadPageState extends State<WeddingUploadPage> {
  final UploadService _uploadService = UploadService();
  bool _isUploading = false;
  double _progress = 0.0;

  // Bohem kır düğünü renk paletimiz
  final Color kirDugunuKrem = const Color(0xFFFDFBF7);
  final Color gulKurusu = const Color(0xFFB76E79);
  final Color yaprakYesili = const Color(0xFF8A9A86);

  void _handleUpload() async {
    setState(() {
      _isUploading = true;
      _progress = 0.0;
    });

    await _uploadService.pickAndUploadAnilar(
      onProgress: (progress) {
        setState(() {
          _progress = progress;
        });
      },
      onSuccess: (message) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: yaprakYesili),
        );
      },
      onError: (error) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kirDugunuKrem,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=1000',
            ), // Düzeltilen şık kır düğünü görseli
            fit: BoxFit.cover,
            opacity: 0.06, // Arka planda çok hafif durması için
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                ), // Webde çok yayılmasın diye limitledik
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Şık Başlık
                    Text(
                      "Hilal & Oğuz 🌿",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: yaprakYesili,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Düğün Anı Paylaşımı",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: gulKurusu,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Bu mutlu güne ait en güzel fotoğraf ve videolarınızı yükleyerek anılarımızı ölümsüzleştirmemize yardımcı olabilirsiniz. 🤍",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Durum Çubuğu veya Yükleme Butonu
                    if (_isUploading) ...[
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: _progress / 100,
                          valueColor: AlwaysStoppedAnimation<Color>(gulKurusu),
                          backgroundColor: yaprakYesili.withOpacity(0.15),
                          strokeWidth: 6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Anılarınız aktarılıyor... %${_progress.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: gulKurusu,
                          fontSize: 15,
                        ),
                      ),
                    ] else ...[
                      // Estetik Butonumuz
                      ElevatedButton.icon(
                        onPressed: _handleUpload,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 22,
                        ),
                        label: const Text(
                          "Fotoğraf / Video Seç ve Gönder",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gulKurusu,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
