import 'package:flutter/material.dart';
import 'dart:ui';
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

  // Lüks Düğün Paleti
  final Color gulKurusu = const Color(0xFFB76E79);
  final Color altinSarisi = const Color(0xFFD4AF37);
  final Color canliAltin = const Color(0xFFF3E5AB);

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
      body: Stack(
        children: [
          // 1. Arka Plan: Derin ve Işıltılı Kır Düğünü Görseli
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
          // Gece ambiyansı katmanı
          Container(color: Colors.black.withValues(alpha: 128)),

          // 2. Ana İçerik Masası
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 16,
                    sigmaY: 16,
                  ), // Premium Cam Efekti
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 26),
                          Colors.white.withValues(alpha: 13),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        width: 1.5,
                        color: Colors.white.withValues(alpha: 77),
                      ), // Parlak kristal kenarlık
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 64),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 50.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Işıltılı Kalp Süslemesi
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 26),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: canliAltin.withValues(alpha: 102),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            "❤️",
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // İsimler (Zarif, büyük ve parıltılı)
                        Text(
                          "Hilal & Oğuz",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: canliAltin,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: const Offset(1, 2),
                                blurRadius: 4,
                              ),
                            ],
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Alt başlık senin isteğine göre güncellendi
                        Text(
                          "B İ R  Ö M Ü R  B O Y U  M U T L U L U Ğ A . . . ✨",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 230),
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        // Özel Degrade Ayraç Çizgisi
                        Container(
                          width: 120,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                altinSarisi,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Yazı boyutu küçültüldü ve şampanya emojisi beyaz kalple değiştirildi
                        Text(
                          "Bu güzel gecede çektiğiniz fotoğrafları ve videoları bizimle paylaşır mısınız? 🤍",
                          style: TextStyle(
                            fontSize:
                                14, // Kısa olduğu için puntosunu hafifçe artırıp tam dengeli yaptık
                            color: Colors.white.withValues(alpha: 220),
                            height: 1.5,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // 3. Durum Alanı (Sayaç veya Lüks Buton)
                        if (_isUploading) ...[
                          Column(
                            children: [
                              // Şık İlerleme Çubuğu (Progress Bar)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _currentFileIndex / _totalFiles,
                                  minHeight: 8,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    canliAltin,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Harika anılar aktarılıyor... ✨",
                                style: TextStyle(
                                  color: canliAltin,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_currentFileIndex / $_totalFiles dosya yüklendi",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 180),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Göz Alıcı, Lüks Tasarımlı Buton
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              gradient: LinearGradient(
                                colors: [gulKurusu, altinSarisi],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gulKurusu.withValues(alpha: 102),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _startNativeWebUpload,
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                "Anıları Seç ve Gönder",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(35),
                                ),
                              ),
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
        ],
      ),
    );
  }
}
