import { Router } from 'express';
import { UsersController } from './users.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.put('/profile', authenticate as any, UsersController.updateProfile as any);

export const userRoutes = router;
