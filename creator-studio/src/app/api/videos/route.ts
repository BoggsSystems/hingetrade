import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get('userId');

  try {

    // Build where clause for filtering
    const where = userId ? { creatorId: userId } : {};

    // Fetch videos from database
    const videos = await db.video.findMany({
      where,
      include: {
        creator: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return NextResponse.json({
      videos,
      total: videos.length,
    });
  } catch (error) {
    console.error('Error fetching videos:', error);
    
    // If database is not available, return mock data for development
    if (error instanceof Error && error.message.includes('connect')) {
      const mockVideos = [
        {
          id: '1',
          title: 'TSLA Technical Analysis - Breakout Strategy',
          description: 'Analysis of Tesla stock showing potential breakout patterns',
          cloudinaryPublicId: 'creator-studio/videos/sample1',
          thumbnailUrl: 'https://res.cloudinary.com/demo/video/upload/w_400,h_300,c_pad,f_jpg/sample1.jpg',
          videoUrl: 'https://res.cloudinary.com/demo/video/upload/sample1.mp4',
          duration: 180,
          fileSize: 25600000,
          status: 'published',
          tags: ['technical-analysis', 'tesla', 'stocks'],
          creatorId: userId || 'user1',
          createdAt: new Date('2024-01-15'),
          updatedAt: new Date('2024-01-15'),
          creator: {
            id: 'user1',
            name: 'Demo User',
            email: 'demo@example.com',
          },
        },
      ];

      const filteredVideos = userId ? mockVideos.filter(v => v.creatorId === userId) : mockVideos;
      return NextResponse.json({
        videos: filteredVideos,
        total: filteredVideos.length,
      });
    }

    return NextResponse.json(
      { error: 'Failed to fetch videos' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      title,
      description,
      cloudinaryPublicId,
      thumbnailUrl,
      videoUrl,
      duration,
      fileSize,
      tags,
      userId,
      format,
    } = body;

    // Validate required fields
    if (!title || !cloudinaryPublicId || !userId) {
      return NextResponse.json(
        { error: 'Missing required fields: title, cloudinaryPublicId, userId' },
        { status: 400 }
      );
    }

    console.log('📥 Creating video with data:', {
      title,
      description,
      cloudinaryPublicId,
      thumbnailUrl,
      videoUrl,
      duration,
      fileSize,
      format,
      tags,
      userId
    });

    try {
      // Create new video record in database
      const newVideo = await db.video.create({
        data: {
          title,
          description: description || null,
          cloudinaryPublicId,
          thumbnailUrl: thumbnailUrl || null,
          videoUrl: videoUrl || null,
          duration: duration ? parseFloat(duration.toString()) : null,
          fileSize: fileSize ? parseInt(fileSize.toString()) : null,
          format: format || null,
          tags: Array.isArray(tags) ? tags : [],
          status: 'processing',
          creatorId: userId,
        },
        include: {
          creator: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
        },
      });

      return NextResponse.json(newVideo, { status: 201 });
    } catch (dbError) {
      console.error('❌ Database error creating video:', dbError);
      console.error('Error details:', {
        message: dbError instanceof Error ? dbError.message : 'Unknown error',
        stack: dbError instanceof Error ? dbError.stack : 'No stack',
      });
      
      // If database is not available, return mock response for development
      if (dbError instanceof Error && dbError.message.includes('connect')) {
        const mockVideo = {
          id: Date.now().toString(),
          title,
          description: description || null,
          cloudinaryPublicId,
          thumbnailUrl: thumbnailUrl || null,
          videoUrl: videoUrl || null,
          duration: duration ? parseFloat(duration.toString()) : null,
          fileSize: fileSize ? parseInt(fileSize.toString()) : null,
          format: format || null,
          tags: Array.isArray(tags) ? tags : [],
          status: 'processing',
          creatorId: userId,
          createdAt: new Date(),
          updatedAt: new Date(),
          creator: {
            id: userId,
            name: 'Demo User',
            email: 'demo@example.com',
          },
        };

        return NextResponse.json(mockVideo, { status: 201 });
      }
      
      throw dbError;
    }
  } catch (error) {
    console.error('Error creating video:', error);
    return NextResponse.json(
      { error: 'Failed to create video' },
      { status: 500 }
    );
  }
}