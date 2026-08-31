import path from 'path';
import multer from 'multer';
import { Request, Response, Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import { config } from '../../config';
import { authenticate } from '../../middlewares/auth.middleware';
import { sendSuccess, sendError } from '../../utils/response';

// ─── Supabase Storage Client ────────────────────────────────────────────────
const supabase = createClient(
  config.storage.supabaseUrl || config.supabase.url,
  config.storage.supabaseKey || config.supabase.serviceRoleKey
);

const BUCKET = config.storage.supabaseBucket || 'estateverify-documents';

// ─── Multer: Memory Storage (no disk write — goes straight to Supabase) ─────
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 150 * 1024 * 1024 }, // 150MB max
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const mime = (file.mimetype || '').toLowerCase();

    const allowedExtensions = [
      // Images
      '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif', '.svg', '.bmp', '.tiff',
      // Videos
      '.mp4', '.mov', '.m4v', '.mkv', '.webm', '.avi', '.3gp', '.3gpp', '.wmv', '.flv',
      // Audio
      '.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac', '.wma', '.opus',
      // Documents
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.csv', '.txt',
    ];

    const isAllowed =
      mime.startsWith('image/') ||
      mime.startsWith('video/') ||
      mime.startsWith('audio/') ||
      mime.includes('pdf') ||
      mime.includes('document') ||
      mime.includes('msword') ||
      mime.includes('officedocument') ||
      mime.includes('sheet') ||
      mime.includes('excel') ||
      allowedExtensions.includes(ext) ||
      mime === 'application/octet-stream';

    if (isAllowed) {
      cb(null, true);
    } else {
      cb(new Error(`File type (${ext || mime}) is not supported.`));
    }
  },
});

const router = Router();

// ─── POST /storage/upload ────────────────────────────────────────────────────
// Authenticated upload → streams file bytes to Supabase Storage → returns CDN URL
router.post('/upload', authenticate as any, (req: Request, res: Response) => {
  upload.any()(req, res, async (err: any) => {
    if (err) {
      const message =
        err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE'
          ? 'File size exceeds the 150MB limit.'
          : err.message || 'Error processing file.';
      sendError(res, message, 400);
      return;
    }

    const file = req.file || (req.files && Array.isArray(req.files) && req.files.length > 0 ? req.files[0] : null);
    if (!file || !file.buffer) {
      sendError(res, 'No file uploaded', 400);
      return;
    }

    try {
      // Build a unique Supabase path: uploads/YYYY/MM/timestamp-random.ext
      const ext = path.extname(file.originalname) || '';
      const uniqueName = `${Date.now()}-${Math.random().toString(36).substring(2, 9)}${ext}`;
      const now = new Date();
      const storagePath = `uploads/${now.getFullYear()}/${String(now.getMonth() + 1).padStart(2, '0')}/${uniqueName}`;

      // Upload to Supabase Storage
      const { data, error } = await supabase.storage
        .from(BUCKET)
        .upload(storagePath, file.buffer, {
          contentType: file.mimetype || 'application/octet-stream',
          upsert: false,
        });

      if (error) {
        console.error('[SUPABASE STORAGE UPLOAD ERROR]', error);
        sendError(res, `Storage upload failed: ${error.message}`, 500);
        return;
      }

      // Get the public URL (permanent CDN link — no expiry)
      const { data: urlData } = supabase.storage.from(BUCKET).getPublicUrl(data.path);
      const fileUrl = urlData.publicUrl;

      sendSuccess(
        res,
        {
          fileName: file.originalname,
          storedName: uniqueName,
          storagePath: data.path,
          fileUrl,
          fileSize: file.size,
          mimeType: file.mimetype,
        },
        'File uploaded securely to Supabase Storage'
      );
    } catch (uploadErr: any) {
      console.error('[STORAGE UPLOAD EXCEPTION]', uploadErr);
      sendError(res, uploadErr?.message || 'Unexpected upload error', 500);
    }
  });
});

// ─── GET /storage/files/:filename ────────────────────────────────────────────
// Legacy compatibility — if someone hits the old local-file endpoint,
// redirect them gracefully rather than 404ing.
router.get('/files/:filename', (_req: Request, res: Response): void => {
  res.status(410).json({
    success: false,
    message: 'Local file serving is no longer supported. All files are served via Supabase CDN.',
  });
});

export const storageRoutes = router;
