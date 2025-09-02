'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { apiClient } from '@/lib/api';
import { Play, Clock, Eye, MoreHorizontal } from 'lucide-react';
import { Button } from '@/components/ui/button';
import ConfirmationModal from '@/components/modals/ConfirmationModal';

interface Video {
  id: string;
  title: string;
  description?: string;
  thumbnailUrl?: string;
  videoUrl?: string;
  duration?: number;
  durationSeconds?: number;
  fileSize?: number;
  viewCount?: number;
  averageWatchTime?: number;
  engagementRate?: number;
  status: string | number;
  tags?: string[];
  createdAt: string | Date;
  creator?: {
    id: string;
    name?: string;
    email: string;
  };
}

interface VideoListProps {
  limit?: number;
  showActions?: boolean;
}

export default function VideoList({ limit, showActions = false }: VideoListProps) {
  const { user } = useAuth();
  const [videos, setVideos] = useState<Video[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    videoId: string;
    videoTitle: string;
    action: 'unpublish';
  } | null>(null);

  useEffect(() => {
    fetchVideos();
  }, [user]);

  const fetchVideos = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const data = await apiClient.get(`/videos?userId=${user.id}`);
      const videoList = limit ? data.videos.slice(0, limit) : data.videos;
      setVideos(videoList);
    } catch (err) {
      console.error('Error fetching videos:', err);
      setError('Failed to load videos');
    } finally {
      setLoading(false);
    }
  };

  const handlePublishVideo = async (videoId: string) => {
    setActionLoading(videoId);
    try {
      console.log('Publishing video:', videoId);
      await apiClient.post(`/videos/${videoId}/publish`);
      console.log('Video published successfully');
      // Refresh the video list to show updated status
      await fetchVideos();
    } catch (err) {
      console.error('Error publishing video:', err);
      const errorMessage = err instanceof Error ? err.message : 'Failed to publish video';
      setError(`Publishing failed: ${errorMessage}`);
      // Clear error after 5 seconds
      setTimeout(() => setError(''), 5000);
    } finally {
      setActionLoading(null);
    }
  };

  const handleUnpublishVideo = async (videoId: string, videoTitle: string) => {
    setConfirmModal({
      isOpen: true,
      videoId,
      videoTitle,
      action: 'unpublish'
    });
  };

  const confirmUnpublishVideo = async () => {
    if (!confirmModal) return;

    setActionLoading(confirmModal.videoId);
    try {
      console.log('Unpublishing video:', confirmModal.videoId);
      await apiClient.post(`/videos/${confirmModal.videoId}/unpublish`, { reason: 'Unpublished by creator' });
      console.log('Video unpublished successfully');
      // Refresh the video list to show updated status
      await fetchVideos();
    } catch (err) {
      console.error('Error unpublishing video:', err);
      const errorMessage = err instanceof Error ? err.message : 'Failed to unpublish video';
      setError(`Unpublishing failed: ${errorMessage}`);
      // Clear error after 5 seconds
      setTimeout(() => setError(''), 5000);
    } finally {
      setActionLoading(null);
      setConfirmModal(null);
    }
  };

  const handleRepublishVideo = async (videoId: string) => {
    setActionLoading(videoId);
    try {
      console.log('Republishing video:', videoId);
      await apiClient.post(`/videos/${videoId}/republish`);
      console.log('Video republished successfully');
      // Refresh the video list to show updated status
      await fetchVideos();
    } catch (err) {
      console.error('Error republishing video:', err);
      const errorMessage = err instanceof Error ? err.message : 'Failed to republish video';
      setError(`Republishing failed: ${errorMessage}`);
      // Clear error after 5 seconds  
      setTimeout(() => setError(''), 5000);
    } finally {
      setActionLoading(null);
    }
  };

  const getActionButtons = (video: Video) => {
    const statusStr = typeof video.status === 'string' ? video.status.toLowerCase() : String(video.status);
    const buttons = [];

    // Ready to Publish -> Show Publish button
    if (statusStr === 'readytopublish' || statusStr === '5') {
      buttons.push(
        <Button
          key="publish"
          size="sm"
          onClick={() => handlePublishVideo(video.id)}
          style={{
            backgroundColor: 'var(--color-positive)',
            color: 'white',
            border: 'none'
          }}
        >
          Publish Now
        </Button>
      );
    }

    // Published -> Show Unpublish button
    if (statusStr === 'published' || statusStr === '6') {
      buttons.push(
        <Button
          key="unpublish"
          variant="outline"
          size="sm"
          onClick={() => handleUnpublishVideo(video.id, video.title)}
        >
          Unpublish
        </Button>
      );
    }

    // Unpublished -> Show Re-publish button
    if (statusStr === 'unpublished' || statusStr === '7') {
      buttons.push(
        <Button
          key="republish"
          size="sm"
          onClick={() => handleRepublishVideo(video.id)}
          style={{
            backgroundColor: 'var(--color-positive)',
            color: 'white',
            border: 'none'
          }}
        >
          Re-publish
        </Button>
      );
    }

    return buttons;
  };

  const formatDuration = (seconds?: number) => {
    if (!seconds) return 'N/A';
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const formatFileSize = (bytes?: number) => {
    if (!bytes) return 'N/A';
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const getVideoStatus = (status: string | number) => {
    const statusStr = typeof status === 'string' ? status.toLowerCase() : String(status);
    
    const statusMap: Record<string, { label: string; color: string; description: string }> = {
      'draft': { label: 'Draft', color: 'var(--color-text-light)', description: 'Video saved as draft' },
      '0': { label: 'Draft', color: 'var(--color-text-light)', description: 'Video saved as draft' },
      
      'uploading': { label: 'Uploading', color: 'var(--color-warning)', description: 'Video is being uploaded' },
      '1': { label: 'Uploading', color: 'var(--color-warning)', description: 'Video is being uploaded' },
      
      'processing': { label: 'Processing', color: 'var(--color-warning)', description: 'Video is being processed' },
      '2': { label: 'Processing', color: 'var(--color-warning)', description: 'Video is being processed' },
      
      'processingfailed': { label: 'Processing Failed', color: 'var(--color-negative)', description: 'Video processing failed' },
      '3': { label: 'Processing Failed', color: 'var(--color-negative)', description: 'Video processing failed' },
      
      'needsreview': { label: 'Needs Review', color: '#ff9500', description: 'Video needs manual review' },
      '4': { label: 'Needs Review', color: '#ff9500', description: 'Video needs manual review' },
      
      'readytopublish': { label: 'Ready to Publish', color: '#007acc', description: 'Video is ready to be published' },
      '5': { label: 'Ready to Publish', color: '#007acc', description: 'Video is ready to be published' },
      
      'published': { label: 'Published', color: 'var(--color-positive)', description: 'Video is live and public' },
      '6': { label: 'Published', color: 'var(--color-positive)', description: 'Video is live and public' },
      
      'unpublished': { label: 'Unpublished', color: '#ff6b6b', description: 'Video was unpublished' },
      '7': { label: 'Unpublished', color: '#ff6b6b', description: 'Video was unpublished' },
      
      'archived': { label: 'Archived', color: 'var(--color-text-light)', description: 'Video is archived' },
      '8': { label: 'Archived', color: 'var(--color-text-light)', description: 'Video is archived' },
      
      'deleted': { label: 'Deleted', color: 'var(--color-negative)', description: 'Video is marked for deletion' },
      '9': { label: 'Deleted', color: 'var(--color-negative)', description: 'Video is marked for deletion' },
    };

    return statusMap[statusStr] || { 
      label: 'Unknown', 
      color: 'var(--color-text-light)', 
      description: 'Unknown status' 
    };
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: '2rem' }}>
        <div className="spinner"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ 
        padding: '2rem', 
        textAlign: 'center', 
        color: 'var(--color-negative)' 
      }}>
        {error}
      </div>
    );
  }

  if (videos.length === 0) {
    return (
      <div style={{ 
        padding: '2rem', 
        textAlign: 'center', 
        color: 'var(--color-text-light)' 
      }}>
        <p>No videos uploaded yet.</p>
        <p style={{ fontSize: 'var(--font-sm)', marginTop: 'var(--spacing-sm)' }}>
          Upload your first video to get started!
        </p>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-md)' }}>
      {videos.map((video) => (
        <div
          key={video.id}
          style={{
            display: 'flex',
            gap: 'var(--spacing-md)',
            padding: 'var(--spacing-md)',
            backgroundColor: 'var(--color-panel)',
            borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-border)',
          }}
        >
          {/* Thumbnail */}
          <div style={{ flexShrink: 0 }}>
            {video.thumbnailUrl ? (
              <img
                src={video.thumbnailUrl}
                alt={video.title}
                style={{
                  width: '120px',
                  height: '90px',
                  objectFit: 'cover',
                  borderRadius: 'var(--radius-sm)',
                }}
              />
            ) : (
              <div
                style={{
                  width: '120px',
                  height: '90px',
                  backgroundColor: 'var(--color-border)',
                  borderRadius: 'var(--radius-sm)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <Play size={24} style={{ color: 'var(--color-text-light)' }} />
              </div>
            )}
          </div>

          {/* Content */}
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <h3 style={{ 
                  fontSize: 'var(--font-lg)', 
                  fontWeight: '600', 
                  marginBottom: 'var(--spacing-xs)',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap'
                }}>
                  {video.title}
                </h3>
                
                {video.description && (
                  <p style={{ 
                    color: 'var(--color-text-light)', 
                    fontSize: 'var(--font-sm)',
                    marginBottom: 'var(--spacing-sm)',
                    overflow: 'hidden',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical'
                  }}>
                    {video.description}
                  </p>
                )}

                {/* Video metadata */}
                <div style={{ 
                  display: 'flex', 
                  gap: 'var(--spacing-lg)', 
                  fontSize: 'var(--font-sm)',
                  color: 'var(--color-text-light)',
                  marginBottom: 'var(--spacing-xs)'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--spacing-xs)' }}>
                    <Eye size={14} />
                    {(video.viewCount || 0).toLocaleString()} views
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--spacing-xs)' }}>
                    <Clock size={14} />
                    {formatDuration(video.durationSeconds) || formatDuration(video.duration) || 'N/A'}
                  </div>
                  <div>
                    Uploaded {new Date(video.createdAt).toLocaleDateString()}
                  </div>
                </div>

                {/* Analytics metadata */}
                {((video.averageWatchTime !== undefined && video.averageWatchTime !== null) || 
                  (video.engagementRate !== undefined && video.engagementRate !== null)) && (
                  <div style={{ 
                    display: 'flex', 
                    gap: 'var(--spacing-lg)', 
                    fontSize: 'var(--font-sm)',
                    color: 'var(--color-text-light)',
                    marginBottom: 'var(--spacing-sm)'
                  }}>
                    {(video.averageWatchTime !== undefined && video.averageWatchTime !== null) && (
                      <div>
                        Avg watch: {formatDuration(video.averageWatchTime)}
                      </div>
                    )}
                    {(video.engagementRate !== undefined && video.engagementRate !== null) && (
                      <div>
                        Engagement: {(video.engagementRate * 100).toFixed(1)}%
                      </div>
                    )}
                  </div>
                )}

                {/* Status and tags */}
                <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--spacing-md)', marginBottom: 'var(--spacing-sm)' }}>
                  <div 
                    style={{ 
                      display: 'inline-flex',
                      alignItems: 'center',
                      padding: '4px 8px',
                      backgroundColor: getVideoStatus(video.status).color + '15',
                      border: `1px solid ${getVideoStatus(video.status).color}`,
                      borderRadius: 'var(--radius-sm)',
                      fontSize: 'var(--font-xs)',
                      fontWeight: '500',
                    }}
                    title={getVideoStatus(video.status).description}
                  >
                    <span style={{ 
                      width: '8px',
                      height: '8px',
                      borderRadius: '50%',
                      backgroundColor: getVideoStatus(video.status).color,
                      marginRight: 'var(--spacing-xs)'
                    }}></span>
                    {getVideoStatus(video.status).label}
                  </div>
                  
                  {video.tags && video.tags.length > 0 && (
                    <div style={{ display: 'flex', gap: 'var(--spacing-xs)', flexWrap: 'wrap' }}>
                      {video.tags.slice(0, 3).map((tag, index) => (
                        <span
                          key={index}
                          style={{
                            fontSize: 'var(--font-xs)',
                            padding: '2px var(--spacing-xs)',
                            backgroundColor: 'var(--color-border)',
                            borderRadius: 'var(--radius-sm)',
                            color: 'var(--color-text-light)',
                          }}
                        >
                          {tag}
                        </span>
                      ))}
                      {video.tags && video.tags.length > 3 && (
                        <span style={{ 
                          fontSize: 'var(--font-xs)', 
                          color: 'var(--color-text-light)' 
                        }}>
                          +{video.tags.length - 3} more
                        </span>
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-xs)', alignItems: 'flex-end' }}>
                {(() => {
                  const actionButtons = getActionButtons(video);
                  return actionButtons.length > 0 ? actionButtons.map((button, index) => (
                    <div key={index}>{button}</div>
                  )) : showActions ? (
                    <Button variant="outline" size="sm">
                      <MoreHorizontal size={16} />
                    </Button>
                  ) : null;
                })()}
              </div>
            </div>
          </div>
        </div>
      ))}
      
      {/* Confirmation Modal */}
      <ConfirmationModal
        isOpen={confirmModal?.isOpen || false}
        onClose={() => setConfirmModal(null)}
        onConfirm={confirmUnpublishVideo}
        title="Unpublish Video"
        message={`Are you sure you want to unpublish "${confirmModal?.videoTitle || 'this video'}"? It will be removed from public feeds and viewers will no longer be able to access it.`}
        confirmText="Unpublish"
        cancelText="Cancel"
        variant="destructive"
        isLoading={actionLoading === confirmModal?.videoId}
      />
    </div>
  );
}