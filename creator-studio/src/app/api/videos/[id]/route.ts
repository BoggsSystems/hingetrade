import { NextRequest, NextResponse } from 'next/server';

// Mock data - same as in the main route for consistency
let videos = [
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
    userId: 'user1',
    createdAt: new Date('2024-01-15').toISOString(),
    updatedAt: new Date('2024-01-15').toISOString(),
  },
];

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const video = videos.find(v => v.id === params.id);
    
    if (!video) {
      return NextResponse.json(
        { error: 'Video not found' },
        { status: 404 }
      );
    }

    return NextResponse.json(video);
  } catch (error) {
    console.error('Error fetching video:', error);
    return NextResponse.json(
      { error: 'Failed to fetch video' },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json();
    const videoIndex = videos.findIndex(v => v.id === params.id);
    
    if (videoIndex === -1) {
      return NextResponse.json(
        { error: 'Video not found' },
        { status: 404 }
      );
    }

    // Update video
    videos[videoIndex] = {
      ...videos[videoIndex],
      ...body,
      updatedAt: new Date().toISOString(),
    };

    return NextResponse.json(videos[videoIndex]);
  } catch (error) {
    console.error('Error updating video:', error);
    return NextResponse.json(
      { error: 'Failed to update video' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const videoIndex = videos.findIndex(v => v.id === params.id);
    
    if (videoIndex === -1) {
      return NextResponse.json(
        { error: 'Video not found' },
        { status: 404 }
      );
    }

    // Remove from array
    const deletedVideo = videos[videoIndex];
    videos.splice(videoIndex, 1);

    // TODO: Also delete from Cloudinary
    // cloudinary.uploader.destroy(deletedVideo.cloudinaryPublicId, { resource_type: 'video' })

    return NextResponse.json({ success: true, video: deletedVideo });
  } catch (error) {
    console.error('Error deleting video:', error);
    return NextResponse.json(
      { error: 'Failed to delete video' },
      { status: 500 }
    );
  }
}