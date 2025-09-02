import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    console.log('Cloudinary webhook received:', body);

    // Handle different notification types
    switch (body.notification_type) {
      case 'upload':
        console.log('Upload completed:', body.public_id);
        // You can add logic here to update your database
        // when the upload is complete
        break;
        
      case 'eager':
        console.log('Eager transformation completed:', body.public_id);
        // Handle when thumbnails/transformations are ready
        break;
        
      default:
        console.log('Unknown notification type:', body.notification_type);
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error processing Cloudinary webhook:', error);
    return NextResponse.json(
      { error: 'Failed to process webhook' },
      { status: 500 }
    );
  }
}