import fs from 'fs';
import path from 'path';
import multer from 'multer';
import { Request, Response, Router } from 'express';
import { config } from '../../config';
import { authenticate } from '../../middlewares/auth.middleware';
import { sendSuccess, sendError } from '../../utils/response';

// Ensure upload directory exists
if (!fs.existsSync(config.storage.uploadDir)) {
  fs.mkdirSync(config.storage.uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, config.storage.uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueName = `${Date.now()}-${Math.random().toString(36).substring(2, 9)}${ext}`;
    cb(null, uniqueName);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 150 * 1024 * 1024 }, // 150MB max for HD videos, audio, and documents
  fileFilter: (req, file, cb) => {
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

    if (
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
      mime === 'application/octet-stream'
    ) {
      cb(null, true);
    } else {
      cb(new Error(`File type (${ext || mime}) is not supported. Please upload a valid image, video, audio, or document.`));
    }
  },
});

const router = Router();

// Upload endpoint with graceful error handling
router.post('/upload', authenticate as any, (req: Request, res: Response, next) => {
  upload.any()(req, res, (err: any) => {
    if (err) {
      const message = err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE'
        ? 'File size exceeds the 150MB limit.'
        : err.message || 'Error uploading file.';
      sendError(res, message, 400);
      return;
    }

    const file = req.file || (req.files && Array.isArray(req.files) && req.files.length > 0 ? req.files[0] : null);
    if (!file) {
      sendError(res, 'No file uploaded', 400);
      return;
    }

    const protocol = req.headers['x-forwarded-proto'] || req.protocol || 'https';
    const host = req.get('host');
    const serverBase = host ? `${protocol}://${host}/api/v1/storage` : config.storage.baseUrl;
    const fileUrl = `${serverBase}/files/${file.filename}`;

    sendSuccess(res, {
      fileName: file.originalname,
      storedName: file.filename,
      fileUrl,
      fileSize: file.size,
      mimeType: file.mimetype,
    }, 'File uploaded securely');
  });
});

// Download/View protected file
router.get('/files/:filename', (req: Request, res: Response): void => {
  const filePath = path.join(config.storage.uploadDir, req.params.filename as string);
  if (!fs.existsSync(filePath)) {
    res.status(404).send('File not found');
    return;
  }
  res.sendFile(filePath);
});

export const storageRoutes = router;
