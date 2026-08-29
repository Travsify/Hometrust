import { Router } from 'express';
import { AuthController } from './auth.controller';
import { validateBody } from '../../middlewares/validate.middleware';
import { authenticate } from '../../middlewares/auth.middleware';
import { registerSchema, loginSchema } from './auth.dto';

const router = Router();

router.post('/register', validateBody(registerSchema), AuthController.register);
router.post('/login', validateBody(loginSchema), AuthController.login);
router.get('/me', authenticate as any, AuthController.getMe as any);

export const authRoutes = router;
