using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TraderApi.Migrations
{
    /// <inheritdoc />
    public partial class InitialTradingTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AssetCache",
                columns: table => new
                {
                    Symbol = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Exchange = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    AssetClass = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Tradable = table.Column<bool>(type: "boolean", nullable: false),
                    Marginable = table.Column<bool>(type: "boolean", nullable: false),
                    Shortable = table.Column<bool>(type: "boolean", nullable: false),
                    EasyToBorrow = table.Column<bool>(type: "boolean", nullable: false),
                    Fractionable = table.Column<bool>(type: "boolean", nullable: false),
                    MinOrderSize = table.Column<decimal>(type: "numeric(18,8)", precision: 18, scale: 8, nullable: true),
                    MinTradeIncrement = table.Column<decimal>(type: "numeric(18,8)", precision: 18, scale: 8, nullable: true),
                    PriceIncrement = table.Column<decimal>(type: "numeric(18,8)", precision: 18, scale: 8, nullable: true),
                    LastUpdated = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AssetCache", x => x.Symbol);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AssetCache_AssetClass",
                table: "AssetCache",
                column: "AssetClass");

            migrationBuilder.CreateIndex(
                name: "IX_AssetCache_LastUpdated",
                table: "AssetCache",
                column: "LastUpdated");

            migrationBuilder.CreateIndex(
                name: "IX_AssetCache_Tradable",
                table: "AssetCache",
                column: "Tradable");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AssetCache");
        }
    }
}
