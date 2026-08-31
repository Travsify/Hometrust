import { Request, Response } from 'express';
import { ReelsService } from './reels.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';
import { prisma } from '../../utils/prisma';
import { DevelopersService } from '../developers/developers.service';

export class ReelsController {
  /**
   * Create a new reel / site update (Developer only)
   */
  static async createPost(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }

      // Enforce: ONLY verified developers or administrators can publish reels
      let developer = await prisma.developer.findUnique({
        where: { userId: req.user.id },
      });

      if (!developer) {
        if (req.user.role === 'DEVELOPER' || req.user.role === 'ADMIN' || req.user.role === 'SUPER_ADMIN') {
          developer = await DevelopersService.getDeveloperByUserId(req.user.id);
        } else {
          sendError(res, 'Access denied: Only verified property developers can publish reels', 403);
          return;
        }
      }

      const {
        mediaUrl,
        mediaType,
        thumbnailUrl,
        caption,
        projectId,
        propertyId,
        tagTitle,
        tagPrice,
      } = req.body;

      if (!mediaUrl) {
        sendError(res, 'Media URL is required', 400);
        return;
      }

      const post = await ReelsService.createPost({
        developerId: developer.id,
        mediaUrl,
        mediaType,
        thumbnailUrl,
        caption,
        projectId,
        propertyId,
        tagTitle,
        tagPrice,
      });

      sendSuccess(res, post, 'Site reel published successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  /**
   * Get Reels Feed (Following vs Discover)
   */
  static async getFeed(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tab = (req.query.tab as 'following' | 'discover') || 'discover';
      const limit = req.query.limit ? parseInt(req.query.limit as string) : 20;
      const developerId = req.query.developerId as string | undefined;
      const includeExpired = req.query.includeExpired === 'true';

      const posts = await ReelsService.getFeed({
        userId: req.user?.id,
        developerId,
        includeExpired,
        tab,
        limit,
      });

      sendSuccess(res, posts, 'Reels feed retrieved successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  /**
   * Get Active Stories (7-day window or top verified developers)
   */
  static async getStories(req: AuthRequest, res: Response): Promise<void> {
    try {
      const stories = await ReelsService.getStories(req.user?.id);
      sendSuccess(res, stories, 'Stories retrieved successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  /**
   * Toggle Like on a Reel
   */
  static async toggleLike(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Authentication required to like posts', 401);
        return;
      }

      const id = req.params.id as string;
      const result = await ReelsService.toggleLike(id, req.user.id);
      sendSuccess(res, result, result.isLiked ? 'Liked post' : 'Unliked post');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  /**
   * Toggle Follow Developer
   */
  static async toggleFollow(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Authentication required to follow developers', 401);
        return;
      }

      const id = req.params.id as string;
      const result = await ReelsService.toggleFollow(id, req.user.id);
      sendSuccess(res, result, result.isFollowing ? 'Followed developer' : 'Unfollowed developer');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  /**
   * Get Developer's Permanent Video Portfolio
   */
  static async getDeveloperPortfolio(req: AuthRequest, res: Response): Promise<void> {
    try {
      const id = req.params.id as string;
      const posts = await ReelsService.getDeveloperPortfolio(id, req.user?.id);
      sendSuccess(res, posts, 'Developer portfolio retrieved successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  /**
   * Record a view
   */
  static async recordView(req: Request, res: Response): Promise<void> {
    try {
      const id = req.params.id as string;
      await ReelsService.incrementViews(id);
      sendSuccess(res, { viewed: true }, 'View recorded');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  /**
   * Delete Reel
   */
  static async deletePost(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }

      const developer = await prisma.developer.findUnique({
        where: { userId: req.user.id },
      });

      if (!developer) {
        sendError(res, 'Developer account not found', 403);
        return;
      }

      const id = req.params.id as string;
      await ReelsService.deletePost(id, developer.id);
      sendSuccess(res, { deleted: true }, 'Reel deleted successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
