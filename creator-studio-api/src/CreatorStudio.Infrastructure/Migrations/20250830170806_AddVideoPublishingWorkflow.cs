using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CreatorStudio.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddVideoPublishingWorkflow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastStatusChange",
                table: "Videos",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PublishCount",
                table: "Videos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "UnpublishedAt",
                table: "Videos",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastStatusChange",
                table: "Videos");

            migrationBuilder.DropColumn(
                name: "PublishCount",
                table: "Videos");

            migrationBuilder.DropColumn(
                name: "UnpublishedAt",
                table: "Videos");
        }
    }
}
