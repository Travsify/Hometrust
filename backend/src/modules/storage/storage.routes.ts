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
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB max
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Unsupported file type. Only JPG, PNG, WEBP, PDF, and DOC/DOCX are allowed.'));
    }
  },
});

const router = Router();

// Upload endpoint
router.post('/upload', authenticate as any, upload.any(), (req: Request, res: Response): void => {
  const file = req.file || (req.files && Array.isArray(req.files) && req.files.length > 0 ? req.files[0] : null);
  if (!file) {
    sendError(res, 'No file uploaded', 400);
    return;
  }

  const fileUrl = `${config.storage.baseUrl}/files/${file.filename}`;

  sendSuccess(res, {
    fileName: file.originalname,
    storedName: file.filename,
    fileUrl,
    fileSize: file.size,
    mimeType: file.mimetype,
  }, 'File uploaded securely');
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
