import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Font garantisi için paketimiz

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
        colorSchemeSeed: const Color(0xFFB59975),
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

  final Color kartBeyazi = const Color(0xFFFDFDFD);
  final Color vizonAltin = const Color(0xFFB59975);
  final Color koyuYazi = const Color(0xFF2C2C2C);
  final Color softYazi = const Color(0xFF666666);

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
              backgroundColor: vizonAltin,
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
          // 💡 LOKAL ARKA PLAN: Artık internet hızı ya da engeller yüzünden asla patlamaz!
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/arka_plan.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.3), // Premium sinematik gölgeleme
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                decoration: BoxDecoration(
                  color: kartBeyazi.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 44.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // İsimler (Premium Davetiye Yazı Tipi)
                    Text(
                      "Hilal & Oğuz",
                      style: GoogleFonts.cinzel(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: koyuYazi,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "2026",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: softYazi,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Eğik Şiirsel Söz (Asil serif el yazısı modu)
                    Text(
                      "\"Anılar, kalbin\nen güzel hazinesidir.\"",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: koyuYazi,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // Alt Açıklama
                    Text(
                      "Fotoğraf ve videolarınızı bizimle paylaşır mısınız?",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: softYazi,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Sabit Metin Alanı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.black12, width: 0.8),
                      ),
                      child: Text(
                        "ADINIZ (İSTEĞE BAĞLI)",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: softYazi.withOpacity(0.6),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Canlı Sayaç ve Yükleme Buton Kontrolü
                    if (_isUploading) ...[
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _currentFileIndex / _totalFiles,
                              minHeight: 6,
                              backgroundColor: vizonAltin.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                vizonAltin,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Anılarınız aktarılıyor... ✨",
                            style: GoogleFonts.montserrat(
                              color: vizonAltin,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "$_currentFileIndex / $_totalFiles dosya yüklendi",
                            style: GoogleFonts.montserrat(
                              color: koyuYazi.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Muhteşem Modern Buton
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startNativeWebUpload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vizonAltin,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            "ANILARI PAYLAŞ",
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Dipnot
                    Text(
                      "* Birden fazla seçim yapabilirsiniz.",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: softYazi.withOpacity(0.7),
                      ),
                    ),
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
