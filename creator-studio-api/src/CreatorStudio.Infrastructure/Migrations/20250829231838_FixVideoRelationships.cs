using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CreatorStudio.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixVideoRelationships : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Videos_CreatorProfiles_CreatorId",
                table: "Videos");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddForeignKey(
                name: "FK_Videos_CreatorProfiles_CreatorId",
                table: "Videos",
                column: "CreatorId",
                principalTable: "CreatorProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
