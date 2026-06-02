const functions = require("firebase-functions/v1");
const { google } = require("googleapis");
const admin = require("firebase-admin");

// 💡 500 HATASININ ÇÖZÜMÜ: Varsayılan bucket adını açıkça belirtiyoruz.
// wedding-1c8cc sizin Firebase proje ID'nizdir.
admin.initializeApp({
    storageBucket: "wedding-1c8cc.appspot.com" 
});

const FOLDER_ID = "1Lb-z0ACuPMEW2MZ7j7B-mExJc5BYO8Lo"; 

exports.shareAnilar = functions
    .runWith({ timeoutSeconds: 60, memory: "256MB" })
    .https.onRequest(async (req, res) => {
        
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

        if (req.method === "OPTIONS") {
            return res.status(204).send("");
        }

        if (req.method !== "POST") {
            return res.status(405).json({ status: "error", message: "Sadece POST desteklenir." });
        }

        try {
            let body = req.body;
            if (typeof body === "string") {
                body = JSON.parse(body);
            }

            const { filename, mimeType, uploaderName } = body;

            if (!filename || !mimeType) {
                return res.status(400).json({ status: "error", message: "filename ve mimeType alanları zorunludur." });
            }

            const bucket = admin.storage().bucket();
            const cleanFilename = filename.replace(/[^a-zA-Z0-9.\\-_]/g, "_");
            const storagePath = `tampon_anilar/${Date.now()}_${cleanFilename}`;
            const file = bucket.file(storagePath);

            // 💡 Güvenli imzalama protokolü v4 yerine v2 veya doğrudan IAM bağımsız token üretimi
            const [uploadUrl] = await file.getSignedUrl({
                version: "v4",
                action: "write",
                expires: Date.now() + 15 * 60 * 1000,
                contentType: mimeType,
                extensionHeaders: {
                    "x-goog-meta-uploader": uploaderName || "Anonim"
                }
            });

            return res.status(200).json({
                status: "success",
                uploadUrl: uploadUrl,
                storagePath: storagePath
            });

        } catch (error) {
            console.error("Signed URL Üretim Hatası:", error);
            // Hata detayını tam görebilmek için response içine ekliyoruz
            return res.status(500).json({ status: "error", message: "Yükleme izni alınamadı.", details: error.toString() });
        }
    });

/**
 * 2. FONKSİYON: Firebase Storage'a yükleme tamamen bittiğinde otomatik tetiklenir.
 * Devasa 4K videoları 'resumable' akışla kesintisiz olarak Google Drive'a taşır.
 */
exports.onTamponAnilarFinalized = functions
    .runWith({ 
        timeoutSeconds: 540, // Süreyi maksimuma (9 dakika) çekiyoruz
        memory: "1GB",        // Akış kontrolü için bellek ayarı
        secrets: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"] 
    })
    .storage.object()
    .onFinalize(async (object) => {
        // Sadece 'tampon_anilar/' klasörüne yüklenen dosyaları işleme alıyoruz
        if (!object.name.startsWith("tampon_anilar/")) return null;

        const bucket = admin.storage().bucket();
        const file = bucket.file(object.name);

        try {
            // 1. Google Drive Yetkilendirmesi
            const oauth2Client = new google.auth.OAuth2(
                process.env.GOOGLE_CLIENT_ID,
                process.env.GOOGLE_CLIENT_SECRET,
                "https://developers.google.com/oauthplayground"
            );
            oauth2Client.setCredentials({ refresh_token: process.env.GOOGLE_REFRESH_TOKEN });
            const driveInstance = google.drive({ version: "v3", auth: oauth2Client });

            // Dosya meta verisinden orijinal ismi ve gönderen bilgisini çözüyoruz
            const originalFilename = object.name.split("/").slice(1).join("_");
            const uploader = object.metadata && object.metadata["uploader"] ? object.metadata["uploader"] : "Anonim";

            const fileMetadata = {
                name: `[${uploader}]_${originalFilename}`,
                parents: [FOLDER_ID]
            };

            const media = {
                mimeType: object.contentType,
                body: file.createReadStream() // RAM'e almadan doğrudan borulama (streaming) yapıyoruz
            };

            // 2. Büyük dosyalar için 'resumable' yükleme modunu başlatıyoruz
            await driveInstance.files.create({
                resource: fileMetadata,
                media: media,
                fields: "id",
                uploadType: "resumable" // 💡 Büyük 4K videolar için hayati önem taşıyan yükleme tipi
            });

            console.log(`Başarıyla Drive'a taşındı: ${object.name}`);

            // 3. Taşıma bittiği için kotayı korumak adına tampon alanındaki dosyayı siliyoruz
            await file.delete();
            return null;

        } catch (error) {
            console.error("Arka Plan Taşıma İşlemi Başarısız Oldu:", error);
            throw error;
        }
    });