import http from 'http';
import app from './app';
import { config } from './config';
import { SocketService } from './modules/chat/socket.service';

const server = http.createServer(app);

// Initialize Socket.io Real-Time Chat & Calling Signaling Gateway
SocketService.init(server);

server.listen(config.port, () => {
  console.log(`=========================================`);
  console.log(` Hometrust API & Real-Time Gateway Server v1.0.0`);
  console.log(` Environment: ${config.nodeEnv}`);
  console.log(` Listening on: http://localhost:${config.port}`);
  console.log(` Health Check: http://localhost:${config.port}/health`);
  console.log(` Socket.io Gateway: Ready for Live Chat & Calling`);
  console.log(`=========================================`);
});

export default server;
