import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
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
  int _totalFiles = 0;
  int _currentFileIndex = 0;

  // Minimalist ve Asil Renk Paleti
  final Color kirDugunuKrem = const Color(0xFFFDFBF7);
  final Color gulKurusu = const Color(0xFFB76E79);
  final Color softSiyah = const Color(0xFF2C2C2C);

  void _startNativeWebUpload() {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.multiple = true;
    uploadInput.accept = 'image/*,video/*';

    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _totalFiles = files.length;
        _currentFileIndex = 0;
      });

      try {
        final url = Uri.parse(
          'https://us-central1-wedding-1c8cc.cloudfunctions.net/shareAnilar',
        );

        for (var file in files) {
          setState(() {
            _currentFileIndex++;
          });

          final request = http.MultipartRequest('POST', url);

          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;

          final List<int> bytes = reader.result as List<int>;

          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          );

          request.files.add(multipartFile);
          request.fields['filename'] = file.name;
          request.fields['mimeType'] = file.type;

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode != 200 && response.statusCode != 201) {
            throw "Sunucu hatası: ${response.statusCode}";
          }
        }

        setState(() {
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Tüm anılarınız başarıyla yüklendi. 🤍"),
              backgroundColor: gulKurusu,
              behavior: SnackBarBehavior.floating,
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
              content: Text("Yükleme başarısız: ${err.toString()}"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
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
      body: Stack(
        children: [
          // Arka Plan: Masalsı ve loş kır düğünü ambiyansı
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1469371670807-013ccf25f16a?q=80&w=1600',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Karartma katmanı (Zarafeti öne çıkarmak için hafifletildi)
          Container(color: Colors.black.withOpacity(0.45)),
          // Ana Davetiye Kartı
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 48.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık (Yaprak kaldırıldı, zarif bir kalp eklendi)
                    Text(
                      "Hilal & Oğuz ❤️",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight:
                            FontWeight.w300, // Daha ince ve asil bir duruş
                        color: softSiyah,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "DÜĞÜN ANI PAYLAŞIMI",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: gulKurusu,
                        letterSpacing: 3, // Premium davetiye havası
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // Minimal Çizgi Ayraç
                    Container(
                      width: 40,
                      height: 1,
                      color: gulKurusu.withOpacity(0.4),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      "Bu özel geceye ait en güzel fotoğraf ve videolarınızı yükleyerek anılarımızı bizimle paylaşabilirsiniz.",
                      style: TextStyle(
                        fontSize: 14,
                        color: softSiyah.withOpacity(0.7),
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 44),
                    // Sayaç ve Yükleme Alanı
                    if (_isUploading) ...[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: _currentFileIndex / _totalFiles,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                gulKurusu,
                              ),
                              backgroundColor: gulKurusu.withOpacity(0.1),
                              strokeWidth: 4,
                            ),
                          ),
                          Text(
                            "$_currentFileIndex/$_totalFiles",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: softSiyah,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Anılar gönderiliyor...\n($_currentFileIndex / $_totalFiles yükleniyor)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: gulKurusu,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ] else ...[
                      // Şık, Sade Buton tasarımı
                      ElevatedButton.icon(
                        onPressed: _startNativeWebUpload,
                        icon: const Icon(Icons.upload_file_rounded, size: 20),
                        label: const Text(
                          "Fotoğraf veya Video Gönder",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gulKurusu,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Keskin boho köşeler yerine daha kibar geçiş
                          ),
                          elevation: 0, // Düz, modern, minimalist görünüm
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
