import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'dart:html' as html; // Tarayıcının yerel dosya seçicisini kullanmak için
import 'package:http/http.dart' as http;

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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFB76E79),
      ),
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
  bool _isUploading = false;

  final Color kirDugunuKrem = const Color.fromARGB(255, 247, 253, 252);
  final Color gulKurusu = const Color(0xFFB76E79);
  final Color yaprakYesili = const Color(0xFF8A9A86);

  // Saf HTML yapısıyla çoklu fotoğraf ve video seçimi
  void _startNativeWebUpload() {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.multiple = true; // Çoklu seçimi aktifleştirir
    uploadInput.accept = 'image/*,video/*'; // Hem fotoğraf hem video kabul eder

    uploadInput.click(); // Kullanıcı için dosya seçme penceresini açar

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      try {
        for (var file in files) {
          String storagePath =
              'tampon_anilar/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final storageRef = FirebaseStorage.instance.ref().child(storagePath);

          // Dosyayı tarayıcı hafızasından doğrudan okuyoruz
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);

          await reader.onLoadEnd.first;
          final List<int> bytes = reader.result as List<int>;

          // Firebase Storage'a yükleme yapıyoruz
          UploadTask uploadTask = storageRef.putData(
            Uint8List.fromList(bytes),
            SettableMetadata(contentType: file.type),
          );

          await uploadTask;

          // Sunucu kopyalama tetiklemesi
          final url = Uri.parse(
            'https://us-central1-wedding-1c8cc.cloudfunctions.net/shareAnilar',
          );
          await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'storagePath': storagePath,
              'filename': file.name,
              'mimeType': file.type,
            }),
          );
        }

        setState(() {
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Harika! Tüm anıların başarıyla yüklendi. 🤍",
              ),
              backgroundColor: yaprakYesili,
            ),
          );
        }
      } catch (err) {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hata Detayı: ${err.toString()}"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });
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
            ),
            fit: BoxFit.cover,
            opacity: 0.06,
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
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    if (_isUploading) ...[
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(gulKurusu),
                          backgroundColor: yaprakYesili.withOpacity(0.15),
                          strokeWidth: 5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Anılarınız aktarılıyor...",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: gulKurusu,
                          fontSize: 15,
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _startNativeWebUpload,
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
