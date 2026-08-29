import app from './app';
import { config } from './config';

const server = app.listen(config.port, () => {
  console.log(`=========================================`);
  console.log(` EstateVerify API Server v1.0.0`);
  console.log(` Environment: ${config.nodeEnv}`);
  console.log(` Listening on: http://localhost:${config.port}`);
  console.log(` Health Check: http://localhost:${config.port}/health`);
  console.log(`=========================================`);
});

export default server;
