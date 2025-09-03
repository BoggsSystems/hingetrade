using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TraderApi.Migrations.AuthDb
{
    /// <inheritdoc />
    public partial class AddAlpacaAccountIdToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AlpacaAccountId",
                table: "AuthUsers",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AlpacaAccountId",
                table: "AuthUsers");
        }
    }
}
