using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class DeleteVideoCommandHandler : IRequestHandler<DeleteVideoCommand, bool>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly IRepository<VideoAnalytics> _analyticsRepository;
    private readonly IUnitOfWork _unitOfWork;

    public DeleteVideoCommandHandler(
        IRepository<Video> videoRepository,
        IRepository<VideoView> viewRepository,
        IRepository<VideoAnalytics> analyticsRepository,
        IUnitOfWork unitOfWork)
    {
        _videoRepository = videoRepository;
        _viewRepository = viewRepository;
        _analyticsRepository = analyticsRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<bool> Handle(DeleteVideoCommand request, CancellationToken cancellationToken)
    {
        var video = await _videoRepository.GetByIdAsync(request.VideoId, cancellationToken);
        
        if (video == null)
        {
            return false;
        }

        try
        {
            await _unitOfWork.BeginTransactionAsync(cancellationToken);

            // Delete related analytics data
            var analytics = await _analyticsRepository.FindAsync(
                a => a.VideoId == request.VideoId, 
                cancellationToken);
            
            if (analytics.Any())
            {
                await _analyticsRepository.DeleteRangeAsync(analytics, cancellationToken);
            }

            // Delete related view data
            var views = await _viewRepository.FindAsync(
                v => v.VideoId == request.VideoId, 
                cancellationToken);
            
            if (views.Any())
            {
                await _viewRepository.DeleteRangeAsync(views, cancellationToken);
            }

            // Delete the video itself
            await _videoRepository.DeleteAsync(video, cancellationToken);

            // Commit transaction
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

            return true;
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw;
        }
    }
}