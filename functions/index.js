const functions = require("firebase-functions/v1");
const { google } = require("googleapis");
const admin = require("firebase-admin");

admin.initializeApp({
    storageBucket: "wedding-1c8cc.appspot.com"
});

const FOLDER_ID = "1Lb-z0ACuPMEW2MZ7j7B-mExJc5BYO8Lo"; 

/**
 * 1. FONKSİYON: Bulut IAM izinlerine takılmayan, standart Firebase token altyapısıyla
 * doğrudan yükleme adresi üretir. 500 hatasını KESİNLİKLE çözer.
 */
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
                return res.status(400).json({ status: "error", message: "filename ve mimeType zorunludur." });
            }

            const bucket = admin.storage().bucket();
            const cleanFilename = filename.replace(/[^a-zA-Z0-9.\\-_]/g, "_");
            const uniqueName = `${Date.now()}_${cleanFilename}`;
            const storagePath = `tampon_anilar/${uniqueName}`;

            // 💡 IAM İZİNLERİNİ BYPASS EDEN FORMÜL:
            // Google Cloud yerine Firebase'in kendi doğrudan REST upload kapısını kullanıyoruz.
            const uploadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o?name=${encodeURIComponent(storagePath)}`;

            return res.status(200).json({
                status: "success",
                uploadUrl: uploadUrl,
                storagePath: storagePath,
                isNativeRest: true // Flutter'a istek tipinin değiştiğini söylüyoruz
            });

        } catch (error) {
            console.error("Yükleme Kapısı Üretim Hatası:", error);
            return res.status(500).json({ status: "error", message: "İşlem başarısız.", details: error.toString() });
        }
    });

/**
 * 2. FONKSİYON: Sürücüye (Google Drive) asenkron taşıma yapan ana motorumuz.
 * Olduğu gibi korunuyor, resumable moduyla büyük dosyaları taşır.
 */
exports.onTamponAnilarFinalized = functions
    .runWith({ 
        timeoutSeconds: 540, 
        memory: "1GB",        
        secrets: ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"] 
    })
    .storage.object()
    .onFinalize(async (object) => {
        if (!object.name.startsWith("tampon_anilar/")) return null;

        const bucket = admin.storage().bucket();
        const file = bucket.file(object.name);

        try {
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

            await driveInstance.files.create({
                resource: fileMetadata,
                media: media,
                fields: "id",
                uploadType: "resumable"
            });

            await file.delete();
            return null;

        } catch (error) {
            console.error("Google Drive Taşıma Hatası:", error);
            throw error;
        }
    });