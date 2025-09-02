using CreatorStudio.Application.Services;
using CreatorStudio.Domain.Services;
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace CreatorStudio.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        // MediatR
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

        // AutoMapper (commented out - add profiles when needed)
        // services.AddAutoMapper(Assembly.GetExecutingAssembly());

        // FluentValidation
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

        // Application Services
        services.AddScoped<IVideoStatusService, VideoStatusService>();
        services.AddScoped<IVideoViewTrackingService, VideoViewTrackingService>();


        // Memory cache for view tracking
        services.AddMemoryCache();

        return services;
    }
}