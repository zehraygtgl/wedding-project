import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

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

  final TextEditingController _nameController = TextEditingController();

  final Color vizonAltin = const Color(0xFFB59975);
  final Color koyuYazi = const Color(
    0xFF2C2C2C,
  ); // Yazılar şık fontu göstersin diye optimize edildi
  final Color softYazi = const Color(0xFF6B6B6B);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startNativeWebUpload() {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.multiple = true;
    uploadInput.accept = 'image/*,video/*';

    final String staticUploaderName = _nameController.text;

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
          request.fields['uploaderName'] = staticUploaderName;

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
          // Ahşap Salon Arka Planı
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/dugun.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.25)),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.93,
                  ), // Hafif saydam asil kart
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                    Divider(color: Colors.black12),
                    // 💡 YENİ İSİM FONTU: İnce, kaba durmayan ve aşırı şık olan Baskerville / Garamond kombinasyonu
                    Text(
                      "Hilal & Oğuz",
                      style: GoogleFonts.pinyonScript(
                        fontSize:
                            52, // Kabalığı önlemek için yazı boyutunu ve rengini optimize ettik
                        color: vizonAltin,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Divider(color: Colors.black12),

                    Text(
                      "2026",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: softYazi,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 💡 ŞIİRSEL SÖZ: Çok daha asil ve modern duran şık Lora Serif yazı tipi
                    Text(
                      "\"Anılar, kalbin\nen güzel hazinesidir.\"",
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: koyuYazi,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    Text(
                      "Fotoğraf ve videolarınızı bizimle paylaşır mısınız?",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: softYazi,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: koyuYazi,
                      ),
                      decoration: InputDecoration(
                        hintText: "ADINIZ (İSTEĞE BAĞLI)",
                        hintStyle: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: softYazi.withOpacity(0.5),
                          letterSpacing: 1.5,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Colors.black12,
                            width: 0.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Colors.black12,
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: vizonAltin, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

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
                            style: GoogleFonts.inter(
                              color: vizonAltin,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "$_currentFileIndex / $_totalFiles dosya yüklendi",
                            style: GoogleFonts.inter(
                              color: koyuYazi.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
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
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Text(
                      "* Birden fazla seçim yapabilirsiniz.",
                      style: GoogleFonts.lora(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: vizonAltin,
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
