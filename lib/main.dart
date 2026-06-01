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

  // Lüks ve Net Okunabilir Renk Paleti
  final Color gulKurusu = const Color(0xFFB76E79);
  final Color altinSarisi = const Color(0xFFD4AF37);
  final Color canliAltin = const Color(0xFFF3E5AB);
  final Color luksKrem = const Color(0xFFFFF8EE);

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
          // Arka Plan Görseli
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
          // Arka planı hafif yumuşatan karanlık katman
          Container(color: Colors.black.withOpacity(0.4)),

          // Ana Kart alanı
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      // 💡 KARTIN RENGİ KOYULAŞTIRILDI: Beyaz yazılar ve altın detaylar net gözüksün diye
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        width: 1,
                        color: gulKurusu.withOpacity(
                          0.4,
                        ), // Gül kurusu zarif çerçeve
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 20,
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
                        // Minimal Kırmızı Kalp Alanı
                        const Text("❤️", style: TextStyle(fontSize: 26)),
                        const SizedBox(height: 16),

                        // İsimler (Canlı Altın Sarısı)
                        Text(
                          "Hilal & Oğuz",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color:
                                canliAltin, // Beyaz yerine altın rengiyle belirginleştirildi
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Alt Başlık (Zarif lüks krem tonu)
                        Text(
                          "B İ R  Ö M Ü R  B O Y U  M U T L U L U Ğ A . . . ✨",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: luksKrem.withOpacity(0.9),
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // İnce Çizgi Ayraç
                        Container(
                          width: 80,
                          height: 1,
                          color: gulKurusu.withOpacity(0.5),
                        ),
                        const SizedBox(height: 24),

                        // Senin İstediğin Kısa ve Net Soru Yazısı (Bembeyaz ve parlak)
                        Text(
                          "Bu güzel gecede çektiğiniz fotoğrafları ve videoları bizimle paylaşır mısınız? 🤍",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors
                                .white, // Tam beyaz yaparak okunurluğu zirveye çıkardık
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 36),

                        // Durum / Buton Kontrolü
                        if (_isUploading) ...[
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _currentFileIndex / _totalFiles,
                                  minHeight: 6,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    canliAltin,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Anılar aktarılıyor... ✨",
                                style: TextStyle(
                                  color: canliAltin,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "$_currentFileIndex / $_totalFiles dosya yüklendi",
                                style: TextStyle(
                                  color: luksKrem.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Buton Alanı
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [gulKurusu, altinSarisi],
                              ),
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
