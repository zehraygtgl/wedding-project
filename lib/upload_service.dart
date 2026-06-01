import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> pickAndUploadAnilar({
    required Function(double progress) onProgress,
    required Function(String message) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Hem fotoğraf hem video seçebilmeyi ve birden fazla seçim yapabilmeyi sağlar
      final List<XFile> files = await picker.pickMultipleMedia();

      if (files.isEmpty) return; // Kullanıcı seçim yapmadıysa çık

      int totalFiles = files.length;
      int completedFiles = 0;

      // Her bir seçilen dosya için sırayla yükleme işlemini başlatıyoruz
      for (var file in files) {
        String storagePath =
            'tampon_anilar/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final storageRef = _storage.ref().child(storagePath);

        final rawBytes = await file.readAsBytes();
        UploadTask uploadTask = storageRef.putData(
          rawBytes,
          SettableMetadata(contentType: file.mimeType),
        );

        // Toplam ilerlemeyi hesaplayıp arayüze gönderiyoruz
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double fileProgress =
              (snapshot.bytesTransferred / snapshot.totalBytes);
          double overallProgress =
              ((completedFiles + fileProgress) / totalFiles) * 100;
          onProgress(overallProgress);
        });

        await uploadTask;

        // Bulut fonksiyonuna kopyalama isteği gönderiyoruz
        final url = Uri.parse(
          'https://us-central1-wedding-1c8cc.cloudfunctions.net/shareAnilar',
        );
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'storagePath': storagePath,
            'filename': file.name,
            'mimeType': file.mimeType ?? 'image/jpeg',
          }),
        );

        completedFiles++;
      }

      onSuccess("Harika! Tüm anıların başarıyla yüklendi. 🤍");
    } catch (e) {
      onError("Yükleme işlemi başarısız: $e");
    }
  }
}
