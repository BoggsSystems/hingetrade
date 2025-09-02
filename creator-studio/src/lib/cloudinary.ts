import { v2 as cloudinary } from 'cloudinary';

// Server-side configuration
cloudinary.config({
  cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

export { cloudinary };

// Client-side configuration
export const cloudinaryConfig = {
  cloudName: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  uploadPreset: process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET,
};

// Upload widget configuration
export const uploadWidgetConfig = {
  cloudName: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  uploadPreset: process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET,
  sources: ['local', 'url', 'camera'],
  multiple: false,
  maxFiles: 1,
  resourceType: 'video',
  clientAllowedFormats: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
  maxFileSize: 100000000, // 100MB
  maxVideoFileSize: 100000000, // 100MB
  folder: 'creator-studio/videos',
  publicId: '', // Will be set dynamically
  tags: ['creator-studio', 'user-upload'],
  context: {
    alt: 'User uploaded video',
    caption: 'Video uploaded via Creator Studio'
  },
  // Video-specific settings
  eager: [
    {
      width: 400,
      height: 300,
      crop: 'pad',
      audio_codec: 'none',
      format: 'jpg'
    },
    {
      width: 1280,
      height: 720,
      crop: 'limit',
      quality: 'auto:good'
    }
  ],
  eagerAsync: true,
  eagerNotificationUrl: process.env.NEXT_PUBLIC_APP_URL + '/api/cloudinary/webhook',
};

// Helper function to generate video URLs
export const getVideoUrl = (publicId: string, options: any = {}) => {
  return cloudinary.url(publicId, {
    resource_type: 'video',
    ...options,
  });
};

// Helper function to generate thumbnail URLs
export const getThumbnailUrl = (publicId: string, options: any = {}) => {
  return cloudinary.url(publicId, {
    resource_type: 'video',
    format: 'jpg',
    width: 400,
    height: 300,
    crop: 'pad',
    ...options,
  });
};

export default cloudinary;