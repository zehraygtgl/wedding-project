const functions = require("firebase-functions/v1");
const { google } = require("googleapis");
const admin = require("firebase-admin");

admin.initializeApp(); 

const FOLDER_ID = "1Lb-z0ACuPMEW2MZ7j7B-mExJc5BYO8Lo"; 

// Eski yükleme kapısı (Artık kullanılmıyor ama eski tarayıcılar hata vermesin diye boş tutuyoruz)
exports.shareAnilar = functions.https.onRequest((req, res) => {
    res.status(200).send("Bu uç nokta artık kullanılmıyor, doğrudan Storage'a yükleniyor.");
});

// ASIL MOTOR: Storage'a dosya düştüğünde uyanıp Drive'a atan tetikleyici
exports.onTamponAnilarFinalized = functions
    .runWith({ 
        timeoutSeconds: 540, 
        memory: "1GB",        
        secrets: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"] 
    })
    .storage.object() // 💡 ÇÖZÜM BURADA: .bucket(...) kısıtlamasını tamamen sildik!
    .onFinalize(async (object) => {
        console.log("SİSTEM UYANDI! Yeni dosya Storage'a geldi:", object.name);

        if (!object.name.startsWith("tampon_anilar/")) {
            console.log("Dosya tampon_anilar klasöründe değil, işlem iptal.");
            return null;
        }

        const bucket = admin.storage().bucket(); // 💡 Burayı da otomatik varsayılan depoya çektik
        const file = bucket.file(object.name);

        try {
            console.log("Drive API yetkilendirmesi başlatılıyor...");
            const oauth2Client = new google.auth.OAuth2(
                process.env.GOOGLE_CLIENT_ID,
                process.env.GOOGLE_CLIENT_SECRET,
                "https://developers.google.com/oauthplayground"
            );
            oauth2Client.setCredentials({ refresh_token: process.env.GOOGLE_REFRESH_TOKEN });
            const driveInstance = google.drive({ version: "v3", auth: oauth2Client });

            const originalFilename = object.name.split("/").slice(1).join("_");
            const uploader = object.metadata && object.metadata["uploader"] ? object.metadata["uploader"] : "Anonim";

            const fileMetadata = {
                name: `[${uploader}]_${originalFilename}`,
                parents: [FOLDER_ID]
            };

            const media = {
                mimeType: object.contentType,
                body: file.createReadStream()
            };

            console.log("Drive'a aktarım başladı...");
            await driveInstance.files.create({
                resource: fileMetadata,
                media: media,
                fields: "id",
                uploadType: "resumable"
            });

            console.log("Başarıyla Drive'a taşındı. Storage temizleniyor...");
            await file.delete();
            return null;

        } catch (error) {
            console.error("KRİTİK HATA! Drive'a taşıma başarısız:", error);
            throw error;
        }
    });