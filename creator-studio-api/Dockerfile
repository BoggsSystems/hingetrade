# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution file
COPY CreatorStudioApi.sln .

# Copy project files
COPY src/CreatorStudio.API/CreatorStudio.API.csproj src/CreatorStudio.API/
COPY src/CreatorStudio.Application/CreatorStudio.Application.csproj src/CreatorStudio.Application/
COPY src/CreatorStudio.Infrastructure/CreatorStudio.Infrastructure.csproj src/CreatorStudio.Infrastructure/
COPY src/CreatorStudio.Domain/CreatorStudio.Domain.csproj src/CreatorStudio.Domain/

# Restore dependencies
RUN dotnet restore

# Copy all source code
COPY . .

# Build the application
WORKDIR /src/src/CreatorStudio.API
RUN dotnet build -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy published application
COPY --from=publish /app/publish .

# Create logs directory
RUN mkdir -p /app/logs

# Set up non-root user for security
RUN useradd -m -s /bin/bash appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Entry point
ENTRYPOINT ["dotnet", "CreatorStudio.API.dll"]