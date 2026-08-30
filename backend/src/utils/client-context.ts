import { Request } from 'express';

export interface ClientContext {
  deviceName: string;
  ipAddress: string;
  userAgent: string;
}

export function extractClientContext(req: Request): ClientContext {
  const forwarded = (req.headers['x-forwarded-for'] as string) || '';
  let ipAddress = (forwarded.split(',')[0] || req.socket.remoteAddress || req.ip || '127.0.0.1')
    .replace('::ffff:', '')
    .trim();

  if (!ipAddress || ipAddress === '127.0.0.1' || ipAddress === '::1') {
    // If running in local testing, display representative IP or gateway address
    ipAddress = (req.headers['x-real-ip'] as string) || ipAddress || '102.89.45.12';
  }

  let deviceName = (req.headers['x-device-name'] as string) || '';
  const userAgent = (req.headers['user-agent'] as string) || 'Hometrust Mobile App';

  if (!deviceName) {
    if (userAgent.includes('Android')) {
      const match = userAgent.match(/Android[^;)]+; ([^;)]+)/);
      deviceName = match && match[1] ? `Android (${match[1].trim()})` : 'Android Mobile Device';
    } else if (userAgent.includes('iPhone')) {
      deviceName = 'Apple iPhone';
    } else if (userAgent.includes('iPad')) {
      deviceName = 'Apple iPad';
    } else if (userAgent.includes('Windows')) {
      deviceName = 'Windows PC (Desktop)';
    } else if (userAgent.includes('Macintosh')) {
      deviceName = 'macOS (Desktop)';
    } else if (userAgent.includes('Dart') || userAgent.includes('flutter') || userAgent.includes('okhttp')) {
      deviceName = 'Hometrust Mobile Client (Android/iOS)';
    } else {
      deviceName = 'Hometrust App Client';
    }
  }

  return {
    deviceName,
    ipAddress,
    userAgent,
  };
}
