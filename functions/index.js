const functions = require("firebase-functions/v1");
const { google } = require("googleapis");
const admin = require("firebase-admin");

admin.initializeApp();


const FOLDER_ID = "1Lb-z0ACuPMEW2MZ7j7B-mExJc5BYO8Lo"; 

exports.shareAnilar = functions
    .runWith({ secrets: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"] })
    .https.onRequest(async (req, res) => {
        
        // CORS Ayarları (Flutter Web'den istek atabilmemiz için şart)
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type");

        if (req.method === "OPTIONS") {
            return res.status(204).send("");
        }

        try {
            let data = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
            
            if (!data || !data.storagePath) {
                return res.status(400).json({ status: "error", message: "Storage path eksik." });
            }

            // 1. Firebase Storage'daki dosyayı hedef alıyoruz (Geçici tampon)
            const bucket = admin.storage().bucket();
            const file = bucket.file(data.storagePath);
            
            const [exists] = await file.exists();
            if (!exists) {
                return res.status(404).json({ status: "error", message: "Dosya tamponda bulunamadı." });
            }

            // 2. Google Drive İstemcisini Kasadaki Şifrelerle Yetkilendiriyoruz
            const oauth2Client = new google.auth.OAuth2(
                process.env.GOOGLE_CLIENT_ID,
                process.env.GOOGLE_CLIENT_SECRET,
                "https://developers.google.com/oauthplayground"
            );
            oauth2Client.setCredentials({ refresh_token: process.env.GOOGLE_REFRESH_TOKEN });
            const driveInstance = google.drive({ version: "v3", auth: oauth2Client });

            // 3. Dosyayı RAM'e yüklemeden doğrudan Storage'dan Drive'a akıtıyoruz (Stream)
            const fileMetadata = {
                name: data.filename || `Anı_${Date.now()}`,
                parents: [FOLDER_ID]
            };

            const media = {
                mimeType: data.mimeType || "image/jpeg",
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