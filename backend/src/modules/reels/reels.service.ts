import { prisma } from '../../utils/prisma';
import { NotificationsService } from '../notifications/notifications.service';

export interface CreatePostParams {
  developerId: string;
  mediaUrl: string;
  mediaType?: 'VIDEO' | 'IMAGE';
  thumbnailUrl?: string;
  caption?: string;
  projectId?: string;
  propertyId?: string;
  tagTitle?: string;
  tagPrice?: string;
}

export class ReelsService {
  /**
   * Create a new developer reel / site post
   */
  static async createPost(params: CreatePostParams) {
    const {
      developerId,
      mediaUrl,
      mediaType = 'VIDEO',
      thumbnailUrl,
      caption,
      projectId,
      propertyId,
    } = params;

    let tagTitle = params.tagTitle;
    let tagPrice = params.tagPrice;

    // Fetch developer info
    const dev = await prisma.developer.findUnique({
      where: { id: developerId },
    });

    if (!dev) {
      throw new Error('Developer account not found');
    }

    // Auto-populate tag details if linked to project
    if (projectId && !tagTitle) {
      const proj = await prisma.project.findUnique({
        where: { id: projectId },
        include: { units: { take: 1, orderBy: { price: 'asc' } } },
      });
      if (proj) {
        tagTitle = `${proj.name} • ${proj.city}`;
        if (!tagPrice && proj.units.length > 0) {
          tagPrice = `Units from ₦${(proj.units[0].price / 1000000).toFixed(1)}M`;
        }
      }
    } else if (propertyId && !tagTitle) {
      const prop = await prisma.property.findUnique({
        where: { id: propertyId },
      });
      if (prop) {
        tagTitle = prop.title;
        if (!tagPrice) {
          tagPrice = `₦${(prop.price / 1000000).toFixed(1)}M`;
        }
      }
    }

    const post = await prisma.developerPost.create({
      data: {
        developerId,
        mediaUrl,
        mediaType,
        thumbnailUrl: thumbnailUrl || (mediaType === 'IMAGE' ? mediaUrl : null),
        caption,
        projectId,
        propertyId,
        tagTitle,
        tagPrice,
      },
      include: {
        developer: true,
        project: true,
        property: true,
      },
    });

    // Notify all followers in the background
    prisma.developerFollower.findMany({
      where: { developerId },
      select: { userId: true },
    }).then(followers => {
      for (const f of followers) {
        NotificationsService.createAndDispatch({
          userId: f.userId,
          title: `🎥 New Site Update from ${dev.companyName}`,
          message: caption || `Check out the latest construction progress at ${tagTitle || dev.companyName}!`,
          type: 'MILESTONE',
          linkUrl: `/reels?postId=${post.id}`,
        }).catch(() => {});
      }
    }).catch(() => {});

    return post;
  }

  /**
   * Get Reels Feed (Following vs Discover)
   */
  static async getFeed(params: {
    userId?: string;
    tab?: 'following' | 'discover';
    limit?: number;
    cursor?: string;
  }) {
    const { userId, tab = 'discover', limit = 20 } = params;

    let whereClause: any = {};

    if (tab === 'following' && userId) {
      const followedDevs = await prisma.developerFollower.findMany({
        where: { userId },
        select: { developerId: true },
      });
      const followedIds = followedDevs.map(f => f.developerId);

      if (followedIds.length > 0) {
        whereClause = { developerId: { in: followedIds } };
      }
      // If user follows no developers yet, fall through to return recent posts
    }

    const posts = await prisma.developerPost.findMany({
      where: whereClause,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        developer: {
          select: {
            id: true,
            companyName: true,
            logoUrl: true,
            isVerified: true,
            userId: true,
          },
        },
        project: {
          select: {
            id: true,
            name: true,
            city: true,
            state: true,
            expectedCompletion: true,
            images: true,
          },
        },
        property: {
          select: {
            id: true,
            title: true,
            price: true,
            city: true,
            state: true,
            images: true,
          },
        },
        likes: userId ? { where: { userId } } : false,
      },
    });

    // Check following status for each developer if user logged in
    let followedDevSet = new Set<string>();
    if (userId) {
      const followers = await prisma.developerFollower.findMany({
        where: { userId },
        select: { developerId: true },
      });
      followedDevSet = new Set(followers.map(f => f.developerId));
    }

    return posts.map(p => ({
      id: p.id,
      developerId: p.developerId,
      mediaUrl: p.mediaUrl,
      mediaType: p.mediaType,
      thumbnailUrl: p.thumbnailUrl,
      caption: p.caption,
      tagTitle: p.tagTitle,
      tagPrice: p.tagPrice,
      viewsCount: p.viewsCount,
      likesCount: p.likesCount,
      sharesCount: p.sharesCount,
      createdAt: p.createdAt,
      developer: p.developer,
      project: p.project,
      property: p.property,
      isLiked: userId ? (p.likes && p.likes.length > 0) : false,
      isFollowing: followedDevSet.has(p.developerId),
    }));
  }

  /**
   * Get Active Stories (7-day window or top verified developers)
   */
  static async getStories(userId?: string) {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // Find recent posts grouped by developer
    const recentPosts = await prisma.developerPost.findMany({
      where: {
        createdAt: { gte: sevenDaysAgo },
      },
      orderBy: { createdAt: 'desc' },
      include: {
        developer: {
          select: {
            id: true,
            companyName: true,
            logoUrl: true,
            isVerified: true,
          },
        },
      },
    });

    const devMap = new Map<string, any>();

    for (const post of recentPosts) {
      if (!devMap.has(post.developerId)) {
        devMap.set(post.developerId, {
          developerId: post.developer.id,
          companyName: post.developer.companyName,
          logoUrl: post.developer.logoUrl,
          isVerified: post.developer.isVerified,
          latestPostId: post.id,
          latestMediaUrl: post.mediaUrl,
          latestMediaType: post.mediaType,
          latestCaption: post.caption,
          postCount: 1,
          createdAt: post.createdAt,
        });
      } else {
        devMap.get(post.developerId).postCount += 1;
      }
    }

    // If fewer than 4 stories, supplement with top verified developers
    if (devMap.size < 4) {
      const topDevs = await prisma.developer.findMany({
        where: {
          isVerified: true,
          id: { notIn: Array.from(devMap.keys()) },
        },
        take: 4 - devMap.size,
        include: {
          posts: { take: 1, orderBy: { createdAt: 'desc' } },
        },
      });

      for (const dev of topDevs) {
        devMap.set(dev.id, {
          developerId: dev.id,
          companyName: dev.companyName,
          logoUrl: dev.logoUrl,
          isVerified: dev.isVerified,
          latestPostId: dev.posts[0]?.id || null,
          latestMediaUrl: dev.posts[0]?.mediaUrl || dev.logoUrl,
          latestMediaType: dev.posts[0]?.mediaType || 'IMAGE',
          latestCaption: dev.posts[0]?.caption || 'Certified Hometrust Developer',
          postCount: dev.posts.length,
          createdAt: dev.createdAt,
        });
      }
    }

    return Array.from(devMap.values());
  }

  /**
   * Toggle Like
   */
  static async toggleLike(postId: string, userId: string) {
    const existing = await prisma.postLike.findUnique({
      where: {
        postId_userId: { postId, userId },
      },
    });

    if (existing) {
      await prisma.postLike.delete({
        where: { id: existing.id },
      });
      const updated = await prisma.developerPost.update({
        where: { id: postId },
        data: { likesCount: { decrement: 1 } },
        select: { likesCount: true },
      });
      return { isLiked: false, likesCount: Math.max(0, updated.likesCount) };
    } else {
      await prisma.postLike.create({
        data: { postId, userId },
      });
      const updated = await prisma.developerPost.update({
        where: { id: postId },
        data: { likesCount: { increment: 1 } },
        select: { likesCount: true },
      });
      return { isLiked: true, likesCount: updated.likesCount };
    }
  }

  /**
   * Toggle Follow Developer
   */
  static async toggleFollow(developerId: string, userId: string) {
    const existing = await prisma.developerFollower.findUnique({
      where: {
        developerId_userId: { developerId, userId },
      },
    });

    if (existing) {
      await prisma.developerFollower.delete({
        where: { id: existing.id },
      });
      return { isFollowing: false };
    } else {
      await prisma.developerFollower.create({
        data: { developerId, userId },
      });
      return { isFollowing: true };
    }
  }

  /**
   * Get Developer's Permanent Video/Photo Portfolio
   */
  static async getDeveloperPortfolio(developerId: string, userId?: string) {
    return prisma.developerPost.findMany({
      where: { developerId },
      orderBy: { createdAt: 'desc' },
      include: {
        project: true,
        property: true,
        likes: userId ? { where: { userId } } : false,
      },
    });
  }

  /**
   * Increment view count
   */
  static async incrementViews(postId: string) {
    return prisma.developerPost.update({
      where: { id: postId },
      data: { viewsCount: { increment: 1 } },
      select: { viewsCount: true },
    }).catch(() => {});
  }

  /**
   * Delete Reel
   */
  static async deletePost(postId: string, developerId: string) {
    const post = await prisma.developerPost.findUnique({
      where: { id: postId },
    });

    if (!post || post.developerId !== developerId) {
      throw new Error('Not authorized to delete this post');
    }

    return prisma.developerPost.delete({
      where: { id: postId },
    });
  }
}
