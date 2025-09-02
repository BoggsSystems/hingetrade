'use client';

import React, { useState, useEffect, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Upload, X, CheckCircle, AlertCircle, Play } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { apiClient } from '@/lib/api';
import './Modal.css';

interface UploadVideoModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: (videoData: any) => void;
}

interface UploadedVideo {
  public_id: string;
  secure_url: string;
  thumbnail_url?: string;
  duration?: number;
  bytes?: number;
  format?: string;
}

export default function UploadVideoModal({ isOpen, onClose, onSuccess }: UploadVideoModalProps) {
  const { user } = useAuth();
  console.log('🎭 UploadVideoModal user:', user);
  const [uploadState, setUploadState] = useState<'idle' | 'uploading' | 'processing' | 'success' | 'error'>('idle');
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadedVideo, setUploadedVideo] = useState<UploadedVideo | null>(null);
  const [videoMetadata, setVideoMetadata] = useState({
    title: '',
    description: '',
    tags: '',
  });
  const [error, setError] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Reset state when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      setUploadState('idle');
      setUploadProgress(0);
      setUploadedVideo(null);
      setVideoMetadata({ title: '', description: '', tags: '' });
      setError('');
      setSelectedFile(null);
    }
  }, [isOpen]);

  // Handle escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen && uploadState !== 'uploading') {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, uploadState, onClose]);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Validate file type
    const allowedTypes = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-matroska', 'video/webm'];
    const allowedExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    
    const isValidType = allowedTypes.includes(file.type) || 
                       allowedExtensions.some(ext => file.name.toLowerCase().endsWith(ext));
    
    if (!isValidType) {
      setError('Please select a valid video file (MP4, MOV, AVI, MKV, WEBM)');
      return;
    }

    // Validate file size (100MB)
    if (file.size > 100 * 1024 * 1024) {
      setError('File size must be less than 100MB');
      return;
    }

    setSelectedFile(file);
    setError('');
    handleUpload(file);
  };

  const handleUploadClick = () => {
    fileInputRef.current?.click();
  };

  const handleUpload = async (file: File) => {
    setUploadState('uploading');
    setUploadProgress(0);

    try {
      // For unsigned uploads, we don't need a signature
      const publicId = `creator-studio/videos/${Date.now()}-${file.name.replace(/\.[^/.]+$/, "")}`;
      
      // Upload to Cloudinary using unsigned preset
      const formData = new FormData();
      formData.append('file', file);
      formData.append('upload_preset', process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET!);
      formData.append('public_id', publicId);
      formData.append('folder', 'creator-studio/videos');
      formData.append('resource_type', 'video');
      formData.append('tags', 'creator-studio,user-upload');

      const xhr = new XMLHttpRequest();

      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) {
          const progress = Math.round((event.loaded / event.total) * 100);
          setUploadProgress(progress);
        }
      });

      xhr.addEventListener('load', () => {
        if (xhr.status === 200) {
          const result = JSON.parse(xhr.responseText);
          console.log('Upload successful:', result);
          
          // Generate thumbnail URL manually for unsigned uploads
          const thumbnailUrl = `https://res.cloudinary.com/${process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME}/video/upload/w_400,h_300,c_pad,f_jpg/${result.public_id}.jpg`;
          
          setUploadedVideo({
            public_id: result.public_id,
            secure_url: result.secure_url,
            thumbnail_url: thumbnailUrl,
            duration: result.duration,
            bytes: result.bytes,
            format: result.format,
          });
          setUploadState('success');
        } else {
          const errorText = xhr.responseText;
          console.error('Upload failed:', xhr.status, errorText);
          throw new Error('Upload failed: ' + errorText);
        }
      });

      xhr.addEventListener('error', () => {
        throw new Error('Upload failed');
      });

      xhr.open('POST', `https://api.cloudinary.com/v1_1/${process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME}/video/upload`);
      xhr.send(formData);

    } catch (error) {
      console.error('Upload error:', error);
      setError(error instanceof Error ? error.message : 'Upload failed. Please try again.');
      setUploadState('error');
    }
  };

  const handleSaveVideo = async () => {
    if (!uploadedVideo || !user) {
      console.error('Missing uploadedVideo or user:', { uploadedVideo: !!uploadedVideo, user });
      return;
    }

    try {
      const savedVideo = await apiClient.post('/videos', {
        title: videoMetadata.title || 'Untitled Video',
        description: videoMetadata.description,
        cloudinaryPublicId: uploadedVideo.public_id,
        thumbnailUrl: uploadedVideo.thumbnail_url,
        videoUrl: uploadedVideo.secure_url,
        duration: uploadedVideo.duration,
        fileSize: uploadedVideo.bytes,
        format: uploadedVideo.format,
        tags: videoMetadata.tags.split(',').map(tag => tag.trim()).filter(Boolean),
        userId: user.id,
      });
      onSuccess?.(savedVideo);
      onClose();
    } catch (error) {
      console.error('Error saving video:', error);
      setError('Failed to save video metadata');
    }
  };

  const handleOverlayClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && uploadState !== 'uploading') {
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={handleOverlayClick}>
      <div className="modal-container upload-video">
        <div className="modal-header">
          <div>
            <h2>Upload Video</h2>
            <p className="modal-subtitle">Share your trading expertise with the community</p>
          </div>
          <button 
            className="modal-close-button" 
            onClick={onClose} 
            type="button"
            disabled={uploadState === 'uploading'}
          >
            ×
          </button>
        </div>

        <div className="modal-content">
          {/* Hidden file input */}
          <input
            ref={fileInputRef}
            type="file"
            accept="video/mp4,video/quicktime,video/x-msvideo,video/x-matroska,video/webm,.mp4,.mov,.avi,.mkv,.webm"
            onChange={handleFileSelect}
            style={{ display: 'none' }}
          />
          
          {uploadState === 'idle' && (
            <div style={{ textAlign: 'center', padding: '2rem' }}>
              <div style={{ 
                border: '2px dashed var(--color-border)', 
                borderRadius: 'var(--radius-lg)',
                padding: '3rem',
                marginBottom: '1rem'
              }}>
                <Upload size={48} style={{ color: 'var(--color-text-light)', marginBottom: '1rem' }} />
                <h3>Upload Your Video</h3>
                <p style={{ color: 'var(--color-text-light)', marginBottom: '1.5rem' }}>
                  Drag and drop your video file or click to browse
                </p>
                <Button onClick={handleUploadClick}>
                  <Upload className="mr-2 h-4 w-4" />
                  Choose Video File
                </Button>
              </div>
              <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-light)' }}>
                Supported formats: MP4, MOV, AVI, MKV, WEBM (max 100MB)
              </p>
            </div>
          )}

          {uploadState === 'uploading' && (
            <div style={{ textAlign: 'center', padding: '2rem' }}>
              <div className="spinner" style={{ marginBottom: '1rem' }}></div>
              <h3>Uploading Video...</h3>
              <div style={{ 
                width: '100%', 
                backgroundColor: 'var(--color-border)', 
                borderRadius: 'var(--radius-md)',
                height: '8px',
                margin: '1rem 0'
              }}>
                <div style={{
                  width: `${uploadProgress}%`,
                  backgroundColor: 'var(--color-positive)',
                  height: '100%',
                  borderRadius: 'var(--radius-md)',
                  transition: 'width 0.3s ease'
                }}></div>
              </div>
              <p style={{ color: 'var(--color-text-light)' }}>{uploadProgress}% complete</p>
            </div>
          )}

          {uploadState === 'success' && uploadedVideo && (
            <div>
              <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
                {uploadedVideo.thumbnail_url ? (
                  <img 
                    src={uploadedVideo.thumbnail_url} 
                    alt="Video thumbnail"
                    style={{ 
                      width: '120px', 
                      height: '90px', 
                      objectFit: 'cover',
                      borderRadius: 'var(--radius-md)'
                    }}
                  />
                ) : (
                  <div style={{
                    width: '120px',
                    height: '90px',
                    backgroundColor: 'var(--color-border)',
                    borderRadius: 'var(--radius-md)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <Play size={24} style={{ color: 'var(--color-text-light)' }} />
                  </div>
                )}
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
                    <CheckCircle size={16} style={{ color: 'var(--color-positive)' }} />
                    <span style={{ color: 'var(--color-positive)', fontWeight: '500' }}>Upload Complete</span>
                  </div>
                  {uploadedVideo.duration && (
                    <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-light)' }}>
                      Duration: {Math.floor(uploadedVideo.duration / 60)}:{(uploadedVideo.duration % 60).toString().padStart(2, '0')}
                    </p>
                  )}
                  {uploadedVideo.bytes && (
                    <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-light)' }}>
                      Size: {(uploadedVideo.bytes / (1024 * 1024)).toFixed(1)} MB
                    </p>
                  )}
                </div>
              </div>

              <div className="modal-form">
                <div className="modal-form-group">
                  <label htmlFor="title">Title *</label>
                  <input
                    id="title"
                    type="text"
                    value={videoMetadata.title}
                    onChange={(e) => setVideoMetadata(prev => ({ ...prev, title: e.target.value }))}
                    placeholder="Enter video title"
                    className="form-control"
                  />
                </div>

                <div className="modal-form-group">
                  <label htmlFor="description">Description</label>
                  <textarea
                    id="description"
                    value={videoMetadata.description}
                    onChange={(e) => setVideoMetadata(prev => ({ ...prev, description: e.target.value }))}
                    placeholder="Describe your video content"
                    rows={3}
                    className="form-control"
                  />
                </div>

                <div className="modal-form-group">
                  <label htmlFor="tags">Tags</label>
                  <input
                    id="tags"
                    type="text"
                    value={videoMetadata.tags}
                    onChange={(e) => setVideoMetadata(prev => ({ ...prev, tags: e.target.value }))}
                    placeholder="Enter tags separated by commas"
                    className="form-control"
                  />
                  <div className="modal-help-text">
                    Example: technical-analysis, stocks, trading-strategy
                  </div>
                </div>
              </div>
            </div>
          )}

          {uploadState === 'error' && (
            <div style={{ textAlign: 'center', padding: '2rem' }}>
              <AlertCircle size={48} style={{ color: 'var(--color-negative)', marginBottom: '1rem' }} />
              <h3>Upload Failed</h3>
              <p style={{ color: 'var(--color-text-light)', marginBottom: '1.5rem' }}>
                {error || 'Something went wrong during upload. Please try again.'}
              </p>
              <Button variant="outline" onClick={() => setUploadState('idle')}>
                Try Again
              </Button>
            </div>
          )}
        </div>

        {uploadState === 'success' && (
          <div className="modal-controls">
            <div className="modal-controls-left">
              <Button
                variant="outline"
                onClick={onClose}
              >
                Cancel
              </Button>
            </div>
            
            <div className="modal-controls-right">
              <Button
                onClick={handleSaveVideo}
                disabled={!videoMetadata.title.trim()}
              >
                Save Video
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}