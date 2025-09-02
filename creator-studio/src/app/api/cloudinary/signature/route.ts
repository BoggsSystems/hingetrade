import { NextRequest, NextResponse } from 'next/server';
import { cloudinary } from '@/lib/cloudinary';

export async function POST(request: NextRequest) {
  try {
    // Note: In production, you should verify the user is authenticated here
    // For now, we'll allow unsigned uploads
    
    const body = await request.json();
    const { public_id, folder, tags, context } = body;

    // Get the current timestamp
    const timestamp = Math.round(Date.now() / 1000);

    // Create parameters for signature
    const params = {
      timestamp,
      public_id,
      folder: folder || 'creator-studio/videos',
      resource_type: 'video',
      tags: tags || 'creator-studio,user-upload',
      context: context || 'alt=User uploaded video|caption=Video uploaded via Creator Studio',
      eager: 'w_400,h_300,c_pad,f_jpg/w_1280,h_720,c_limit,q_auto:good',
      eager_async: true,
    };

    // Generate signature
    const signature = cloudinary.utils.api_sign_request(
      params,
      process.env.CLOUDINARY_API_SECRET!
    );

    return NextResponse.json({
      signature,
      timestamp,
      api_key: process.env.CLOUDINARY_API_KEY,
      cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
      ...params,
    });
  } catch (error) {
    console.error('Error generating Cloudinary signature:', error);
    return NextResponse.json(
      { error: 'Failed to generate upload signature' },
      { status: 500 }
    );
  }
}