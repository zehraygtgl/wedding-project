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
        colorSchemeSeed: const Color(0xFFB76E79), // Gül kurusu tabanlı palet
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

  // Bohem kır düğünü renk paleti
  final Color kirDugunuKrem = const Color(0xFFFDFBF7);
  final Color gulKurusu = const Color(0xFFB76E79);
  final Color yaprakYesili = const Color(0xFF8A9A86);

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
              content: const Text(
                "Harika! Tüm anıların başarıyla yüklendi. 🤍",
              ),
              backgroundColor: yaprakYesili,
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
          // Arka Plan: Şık, loş ve masalsı bir kır düğünü masa konsepti görseli
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
          // Görselin üzerine asil durması ve yazıları okunur kılması için soft bir gölge katmanı
          Container(color: Colors.black.withOpacity(0.4)),
          // Ana İçerik Kartı
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black45,
                color: Colors.white.withOpacity(0.93),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 44.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zarif Boho Çiçek Detayı veya Süsleme Simgesi
                      Icon(
                        Icons.wb_twilight_rounded,
                        color: gulKurusu,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      // Başlık
                      Text(
                        "Hilal & Oğuz 🌿",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: yaprakYesili,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Düğün Anı Paylaşımı",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // İnce Şık Ayraç Çizgisi
                      Container(
                        width: 60,
                        height: 1.5,
                        color: gulKurusu.withOpacity(0.5),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Bu büyüleyici geceye ait en güzel fotoğraf ve videolarınızı yükleyerek anılarımızı bizimle birlikte ölümsüzleştirebilirsiniz. 🤍",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Durum Alanı (Yükleniyor veya Buton)
                      if (_isUploading) ...[
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: _currentFileIndex / _totalFiles,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  gulKurusu,
                                ),
                                backgroundColor: yaprakYesili.withOpacity(0.15),
                                strokeWidth: 5,
                              ),
                            ),
                            Text(
                              "$_currentFileIndex/$_totalFiles",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: yaprakYesili,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Anılarınız aktarılıyor...\n($_currentFileIndex / $_totalFiles dosya gönderildi)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: gulKurusu,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ] else ...[
                        // Büyük ve Şık Yükleme Butonu
                        ElevatedButton.icon(
                          onPressed: _startNativeWebUpload,
                          icon: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 24,
                          ),
                          label: const Text(
                            "Fotoğraf / Video Seç ve Gönder",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gulKurusu,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                            elevation: 4,
                            shadowColor: gulKurusu.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
