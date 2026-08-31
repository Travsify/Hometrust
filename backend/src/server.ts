import http from 'http';
import app from './app';
import { config } from './config';
import { SocketService } from './modules/chat/socket.service';
import { PurchasesService } from './modules/purchases/purchases.service';

const server = http.createServer(app);

// Initialize Socket.io Real-Time Chat & Calling Signaling Gateway
SocketService.init(server);

// Periodic 30-Minute Atomic Lock Release & Warning Monitor (every 60s)
setInterval(async () => {
  try {
    const res = await PurchasesService.releaseExpiredLocks();
    if (res.released > 0 || res.warned > 0) {
      console.log(`[LockExpiryMonitor] Processed: ${res.released} locks released, ${res.warned} warning notifications dispatched.`);
    }
  } catch (err) {
    console.error('[LockExpiryMonitor] Error running releaseExpiredLocks:', err);
  }
}, 60 * 1000);

server.listen(config.port, () => {
  console.log(`=========================================`);
  console.log(` Hometrust API & Real-Time Gateway Server v1.0.0`);
  console.log(` Environment: ${config.nodeEnv}`);
  console.log(` Listening on: http://localhost:${config.port}`);
  console.log(` Health Check: http://localhost:${config.port}/health`);
  console.log(` Socket.io Gateway: Ready for Live Chat & Calling`);
  console.log(` 30-Min Lock Expiry Monitor: Running (every 60s)`);
  console.log(`=========================================`);
});

export default server;
