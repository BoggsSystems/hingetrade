using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public record GetVideoByIdQuery(Guid VideoId) : IRequest<VideoDto?>;