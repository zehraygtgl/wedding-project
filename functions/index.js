const functions = require("firebase-functions/v1");
const { google } = require("googleapis");
const admin = require("firebase-admin");
const Busboy = require("busboy"); // Yeni eklediğimiz form çözücü paket

admin.initializeApp();

const FOLDER_ID = "1Lb-z0ACuPMEW2MZ7j7B-mExJc5BYO8Lo"; 

exports.shareAnilar = functions
    .runWith({ secrets: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"] })
    .https.onRequest((req, res) => { // async kelimesini busboy iç yapısı için dışarı aldık
        
        // CORS Ayarları (Flutter Web'den istek atabilmemiz için şart)
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type");

        if (req.method === "OPTIONS") {
            return res.status(204).send("");
        }

        if (req.method !== "POST") {
            return res.status(405).json({ status: "error", message: "Sadece POST desteklenir." });
        }

        const busboy = Busboy({ headers: req.headers });
        const bucket = admin.storage().bucket();
        
        let uploadPromise = null;
        let storagePath = "";
        let filename = "";
        let mimeType = "";

        // Flutter'dan gelen ek alanları (fields) yakalıyoruz
        busboy.on("field", (fieldname, val) => {
            if (fieldname === "filename") filename = val;
            if (fieldname === "mimeType") mimeType = val;
        });

        // Flutter'dan gelen ham dosyayı akış (stream) halindeyken yakalayıp Firebase Storage'a yazıyoruz
        busboy.on("file", (fieldname, fileStream, fileInfo) => {
            // Eğer Flutter field'ları gönderemezse tarayıcıdan gelen orijinal isimleri yedekliyoruz
            if (!filename) filename = fileInfo.filename;
            if (!mimeType) mimeType = fileInfo.mimeType;

            storagePath = `tampon_anilar/${Date.now()}_${filename}`;
            const gcsFile = bucket.file(storagePath);

            // Dosya verisini RAM'i şişirmeden doğrudan Firebase Storage'a akıtıyoruz
            uploadPromise = new Promise((resolve, reject) => {
                const writeStream = gcsFile.createWriteStream({
                    metadata: { contentType: mimeType }
                });

                fileStream.pipe(writeStream);

                writeStream.on("finish", () => resolve());
                writeStream.on("error", (err) => reject(err));
            });
        });

        // Dosya alımı bittiğinde asıl Drive taşıma operasyonunu başlatıyoruz
        busboy.on("finish", async () => {
            try {
                if (uploadPromise) {
                    await uploadPromise; // Storage'a yazma işleminin bitmesini bekle
                } else {
                    return res.status(400).json({ status: "error", message: "Yüklenecek dosya bulunamadı." });
                }

                // 1. Firebase Storage'daki dosyayı hedef alıyoruz (Geçici tampon)
                const file = bucket.file(storagePath);
                const [exists] = await file.exists();
                if (!exists) {
                    return res.status(404).json({ status: "error", message: "Dosya tamponda oluşturulamadı." });
                }

                // 2. Google Drive İstemcisini Kasadaki Şifrelerle Yetkilendiriyoruz
                const oauth2Client = new google.auth.OAuth2(
                    process.env.GOOGLE_CLIENT_ID,
                    process.env.GOOGLE_CLIENT_SECRET,
                    "https://developers.google.com/oauthplayground"
                );
                oauth2Client.setCredentials({ refresh_token: process.env.GOOGLE_REFRESH_TOKEN });
                const driveInstance = google.drive({ version: "v3", auth: oauth2Client });

                // 3. Dosyayı doğrudan Storage'dan Drive'a akıtıyoruz (Stream)
                const fileMetadata = {
                    name: filename || `Anı_${Date.now()}`,
                    parents: [FOLDER_ID]
                };

                const media = {
                    mimeType: mimeType || "image/jpeg",
                    body: file.createReadStream() 
                };

                const response = await driveInstance.files.create({
                    resource: fileMetadata,
                    media: media,
                    fields: "id",
                    uploadType: "multipart"
                });

                // 4. Taşıma Başarılı! Kotayı korumak için Storage'daki tamponu anında siliyoruz
                await file.delete();

                return res.status(200).json({ 
                    status: "success", 
                    message: "Drive'a başarıyla aktarıldı, tampon temizlendi.", 
                    fileId: response.data.id 
                });

            } catch (error) {
                console.error("Kritik Taşıma Hatası:", error);
                return res.status(500).json({ status: "error", message: "İşlem başarısız.", details: error.toString() });
            }
        });

        // İstek hatası durumunda busboy'u güvenli kapat
        busboy.on("error", (err) => {
            return res.status(500).json({ status: "error", message: "Form ayrıştırma hatası.", details: err.toString() });
        });

        // İstek gövdesini busboy'a vererek motoru çalıştırıyoruz
        if (req.rawBody) {
            busboy.end(req.rawBody);
        } else {
            req.pipe(busboy);
        }
    });