using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TraderApi.Migrations.AuthDb
{
    /// <inheritdoc />
    public partial class AddKycStatusAndProgress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "KycApprovedAt",
                table: "AuthUsers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "KycStatus",
                table: "AuthUsers",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "KycSubmittedAt",
                table: "AuthUsers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "KycProgress",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    HasPersonalInfo = table.Column<bool>(type: "boolean", nullable: false),
                    HasAddress = table.Column<bool>(type: "boolean", nullable: false),
                    HasIdentity = table.Column<bool>(type: "boolean", nullable: false),
                    HasDocuments = table.Column<bool>(type: "boolean", nullable: false),
                    HasFinancialProfile = table.Column<bool>(type: "boolean", nullable: false),
                    HasAgreements = table.Column<bool>(type: "boolean", nullable: false),
                    HasBankAccount = table.Column<bool>(type: "boolean", nullable: false),
                    PersonalInfoData = table.Column<string>(type: "text", nullable: true),
                    AddressData = table.Column<string>(type: "text", nullable: true),
                    IdentityData = table.Column<string>(type: "text", nullable: true),
                    DocumentsData = table.Column<string>(type: "text", nullable: true),
                    FinancialProfileData = table.Column<string>(type: "text", nullable: true),
                    AgreementsData = table.Column<string>(type: "text", nullable: true),
                    BankAccountData = table.Column<string>(type: "text", nullable: true),
                    LastUpdated = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CurrentStep = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_KycProgress", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_KycProgress_AuthUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AuthUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "KycProgress");

            migrationBuilder.DropColumn(
                name: "KycApprovedAt",
                table: "AuthUsers");

            migrationBuilder.DropColumn(
                name: "KycStatus",
                table: "AuthUsers");

            migrationBuilder.DropColumn(
                name: "KycSubmittedAt",
                table: "AuthUsers");
        }
    }
}
