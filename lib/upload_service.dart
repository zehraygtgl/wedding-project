import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> pickAndUploadAni({
    required Function(double progress) onProgress,
    required Function(String message) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      // Davetlinin video veya fotoğraf seçmesini sağlıyoruz (Galeri açılır)
      final XFile? file = await picker.pickVideo(source: ImageSource.gallery);

      if (file == null) return; // Kullanıcı seçim yapmaktan vazgeçerse çık

      // 1. Dosyaya benzersiz bir yol (path) atıyoruz
      String storagePath =
          'tampon_anilar/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = _storage.ref().child(storagePath);

      // 2. Web uyumlu yüklemeyi (bytes üzerinden) başlatıyoruz
      final rawBytes = await file.readAsBytes();
      UploadTask uploadTask = storageRef.putData(
        rawBytes,
        SettableMetadata(contentType: file.mimeType),
      );

      // 3. Yükleme yüzdesini anlık olarak UI (arayüz) katmanına besliyoruz (Progress Bar için)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        onProgress(progress);
      });

      // Yüklemenin Firebase Storage tamponuna tamamen bitmesini bekliyoruz
      await uploadTask;

      // 4. Standart HTTP POST isteğiyle Cloud Function'ı tetikliyoruz
      final url = Uri.parse(
        'https://us-central1-wedding-1c8cc.cloudfunctions.net/shareAnilar',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'storagePath': storagePath,
          'filename': file.name,
          'mimeType': file.mimeType ?? 'image/jpeg',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        onSuccess("Harika! Anın başarıyla yüklendi. 🤍");
      } else {
        onError("Sunucu kopyalama hatası: Kod ${response.statusCode}");
      }
    } catch (e) {
      onError("Yükleme işlemi başarısız: $e");
    }
  }
}
