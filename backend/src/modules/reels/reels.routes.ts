import { Router } from 'express';
import { ReelsController } from './reels.controller';
import { requireAuth, optionalAuth } from '../../middlewares/auth.middleware';

const router = Router();

// Feed & Stories
router.get('/feed', optionalAuth, ReelsController.getFeed);
router.get('/stories', optionalAuth, ReelsController.getStories);
router.get('/developers/:id', optionalAuth, ReelsController.getDeveloperPortfolio);

// Actions
router.post('/view/:id', ReelsController.recordView);
router.post('/like/:id', requireAuth, ReelsController.toggleLike);
router.post('/developers/:id/follow', requireAuth, ReelsController.toggleFollow);

// Developer Post Publishing, Update & Deletion
router.post('/', requireAuth, ReelsController.createPost);
router.patch('/:id', requireAuth, ReelsController.updatePost);
router.put('/:id', requireAuth, ReelsController.updatePost);
router.delete('/:id', requireAuth, ReelsController.deletePost);

export const reelsRoutes = router;
