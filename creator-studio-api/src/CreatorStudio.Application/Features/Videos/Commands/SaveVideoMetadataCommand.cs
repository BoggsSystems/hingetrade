using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public record SaveVideoMetadataCommand(SaveVideoMetadataDto VideoMetadata) : IRequest<VideoDto>;