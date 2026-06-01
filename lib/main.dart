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
        colorSchemeSeed: const Color(0xFFB76E79), // Gül kurusu temeli
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

  // Cıvıl Cıvıl Yaz Düğünü Renk Paleti
  final Color gulKurusu = const Color(0xFFB76E79);
  final Color yaprakYesili = const Color(0xFF6B8E23); // Canlı kır yesili
  final Color yazGunesi = const Color(0xFFFAA462); // Sıcak neşeli turuncu/sarı
  final Color derinSiyah = const Color(0xFF333333);

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
          // 1. Yeni Arka Plan: Capcanlı, gün ışığıyla yıkanan, çiçekli neşeli bir yaz kır düğünü konsepti
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?q=80&w=1600',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Görselin renklerini söndürmeyen, sadece yaz aylarının o soft sıcaklığını veren çok hafif bir filtre
          Container(color: Colors.white.withOpacity(0.15)),

          // 2. Cıvıl Cıvıl Parlayan Kristal Kart
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10,
                    sigmaY: 10,
                  ), // Kristal cam parlaklığı
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      // 💡 KART BEMBEYAZ PARILTIYA DÖNDÜ: İç açıcı yaz enerjisi
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.85),
                          Colors.white.withOpacity(0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        width: 1.5,
                        color: gulKurusu.withOpacity(
                          0.5,
                        ), // Çerçeveniz neşeli gül kurusu
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: yaprakYesili.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 48.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sevimli Kırmızı Kalp
                        const Text("❤️", style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 16),

                        // İsimler (Gül Kurusu asaletinde ve kocaman)
                        Text(
                          "Hilal & Oğuz",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: gulKurusu,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Alt Başlık (Canlı Yaprak Yeşili Tonu)
                        Text(
                          "B İ R  Ö M Ü R  B O Y U  M U T L U L U Ğ A . . . ✨",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: yaprakYesili,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Zarif Renkli Ayraç
                        Container(
                          width: 80,
                          height: 1.5,
                          color: gulKurusu.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),

                        // Senin İstediğin O Kısa, Net Soru Cümlesi (Derin siyahla çok net okunuyor)
                        Text(
                          "Bu güzel gecede çektiğiniz fotoğrafları ve videoları bizimle paylaşır mısınız? 🤍",
                          style: TextStyle(
                            fontSize: 14.5,
                            color:
                                derinSiyah, // Beyaz kartın üzerinde cam gibi net okunuyor
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 36),

                        // 3. Durum / Buton Kontrolü
                        if (_isUploading) ...[
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _currentFileIndex / _totalFiles,
                                  minHeight: 6,
                                  backgroundColor: gulKurusu.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    gulKurusu,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Anılar aktarılıyor... ✨",
                                style: TextStyle(
                                  color: gulKurusu,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "$_currentFileIndex / $_totalFiles dosya yüklendi",
                                style: TextStyle(
                                  color: derinSiyah.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Neşeli, Cıvıl Cıvıl Yaz Butonu
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  gulKurusu,
                                  yazGunesi,
                                ], // Enerjik, güneşli geçiş
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gulKurusu.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _startNativeWebUpload,
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                "Anıları Seç ve Gönder",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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
