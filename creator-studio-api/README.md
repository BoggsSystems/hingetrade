# Creator Studio API

A .NET Core 8 backend API for the HingeTrade Creator Studio application, enabling trading educators to create, manage, and monetize video content.

## Architecture

This API follows Clean Architecture principles with the following layers:

- **Domain**: Core business entities, enums, interfaces, and domain events
- **Application**: Business logic, CQRS commands/queries using MediatR, DTOs
- **Infrastructure**: Data access, external services (Cloudinary), repositories
- **API**: Web API controllers, authentication, middleware

## Features

- **Video Management**: Upload, process, and manage trading education videos
- **Cloudinary Integration**: Video processing, transcoding, and CDN delivery
- **User Management**: Creator profiles, subscriber management
- **Analytics**: Video performance tracking and monetization metrics
- **Background Processing**: Async video processing with status updates

## Tech Stack

- **.NET 8**: Modern C# with minimal APIs and performance improvements
- **PostgreSQL**: Primary database with Entity Framework Core
- **Cloudinary**: Video processing and CDN
- **MediatR**: CQRS pattern implementation
- **AutoMapper**: Object-to-object mapping
- **FluentValidation**: Input validation
- **Docker**: Containerized deployment

## Getting Started

### Prerequisites

- .NET 8 SDK
- PostgreSQL 12+
- Cloudinary account (for video processing)

### Configuration

1. Update `appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=creator_studio_dev;Username=postgres;Password=your-password",
    "Cloudinary": "cloudinary://api-key:api-secret@cloud-name"
  }
}
```

2. Create the database:

```bash
# Run migrations (once EF migrations are added)
dotnet ef database update --project src/CreatorStudio.Infrastructure --startup-project src/CreatorStudio.API
```

### Running the API

```bash
# From the root directory
dotnet run --project src/CreatorStudio.API
```

The API will be available at:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:7000`
- OpenAPI/Swagger: `http://localhost:5000/openapi`

### Health Checks

- Database: `GET /health`

## API Endpoints

### Videos

- `POST /api/videos/upload` - Upload a new video
- `GET /api/videos/{videoId}` - Get video details
- `GET /api/videos/{videoId}/status` - Get processing status
- `GET /api/videos/creator/{creatorId}` - Get creator's videos
- `PUT /api/videos/{videoId}` - Update video details
- `DELETE /api/videos/{videoId}` - Delete video
- `POST /api/videos/{videoId}/publish` - Publish video

## Database Schema

### Core Entities

- **Users**: User accounts and authentication
- **CreatorProfiles**: Creator-specific information and settings
- **Videos**: Video metadata, processing status, and analytics
- **VideoViews**: Individual view tracking for analytics
- **VideoAnalytics**: Aggregated daily analytics data
- **Subscriptions**: User subscriptions to creators
- **Tags**: Video tagging system

## Development

### Adding Migrations

```bash
dotnet ef migrations add MigrationName --project src/CreatorStudio.Infrastructure --startup-project src/CreatorStudio.API
```

### Testing

```bash
dotnet test
```

## Integration with Frontend

This API is designed to work with the Next.js Creator Studio frontend located in the `creator-studio` folder. The API provides:

- RESTful endpoints for video management
- Real-time updates for video processing status
- Authentication integration with HingeTrade platform
- Analytics data for creator dashboards

## Integration with HingeTrade Platform

The API publishes events when videos are created/updated that can be consumed by the main HingeTrade platform:

- **VideoPublishedEvent**: When a video goes live
- **VideoAnalyticsEvent**: Daily analytics updates
- **CreatorProfileUpdatedEvent**: Creator profile changes

## Deployment

### Docker

```bash
# Build and run with Docker Compose
docker-compose up --build
```

### Environment Variables

- `ASPNETCORE_ENVIRONMENT`: Development/Production
- `ConnectionStrings__DefaultConnection`: PostgreSQL connection string
- `ConnectionStrings__Cloudinary`: Cloudinary connection string
- `ApiBaseUrl`: Base URL for webhook callbacks

## Contributing

1. Follow Clean Architecture principles
2. Use CQRS pattern for new features
3. Add unit tests for business logic
4. Update API documentation
5. Follow existing naming conventions