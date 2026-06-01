import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

      // 4. Tampon doldu! Şimdi arka planda az önce yazdığımız Drive tetikleyici fonksiyonunu çağırıyoruz
      final HttpsCallable callable = _functions.httpsCallable('shareAnilar');
      final response = await callable.call({
        'storagePath': storagePath,
        'filename': file.name,
        'mimeType': file.mimeType,
      });

      if (response.data['status'] == 'success') {
        onSuccess("Harika! Anın başarıyla yüklendi. 🤍");
      } else {
        onError("Sunucu kopyalama hatası: ${response.data['message']}");
      }
    } catch (e) {
      onError("Yükleme işlemi başarısız: $e");
    }
  }
}
