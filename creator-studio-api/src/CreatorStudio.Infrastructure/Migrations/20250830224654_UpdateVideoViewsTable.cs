using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CreatorStudio.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateVideoViewsTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeviceType",
                table: "VideoViews",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReferrerUrl",
                table: "VideoViews",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TrafficSource",
                table: "VideoViews",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeviceType",
                table: "VideoViews");

            migrationBuilder.DropColumn(
                name: "ReferrerUrl",
                table: "VideoViews");

            migrationBuilder.DropColumn(
                name: "TrafficSource",
                table: "VideoViews");
        }
    }
}
