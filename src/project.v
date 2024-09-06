/*
 * Copyright (c) 2024 Nicklaus Thompson
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_NicklausThompson_SkyKing (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // VGA signals
	wire hsync;
	wire vsync;
	wire [1:0] R;
	wire [1:0] G;
	wire [1:0] B;
	wire video_active;
	wire [9:0] pix_x;
	wire [9:0] pix_y;

	// BNC signals
	wire [7:0] BNC_x;
	wire [6:0] BNC_y;
	wire BNC_trig;

	// PMODs
	wire [7:0] VGA_out, BNC1_out, BNC2Y_out, BNC2X_out;
	assign VGA_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
	assign BNC1_out = {BNC_x[0], BNC_x[2], BNC_y[0], BNC_y[2], BNC_x[1], BNC_x[3], BNC_y[1], BNC_trig};
	assign BNC2Y_out = {8'hFF};
	assign BNC2X_out = {8'hFF};
	assign uio_oe  = 8'hFF;

	// 2'b00: VGA
	// 2'b01: XY1
	// 2'b11: XY2
	assign uo_out = ui_in[0] ? (ui_in[1] ? BNC2Y_out : BNC1_out) : VGA_out;
	assign uio_out = ui_in[1] ? BNC2X_out : 8'h00;

	// Sync generator and VGA XY coordinate reference
	hvsync_generator hvsync_gen(
		.clk(clk),
		.reset(~rst_n),
		.hsync(hsync),
		.vsync(vsync),
		.display_on(video_active),
		.hpos(pix_x),
		.vpos(pix_y)
	);

	// Suppress unused signals warning
	wire _unused_ok = &{ena, ui_in, uio_in};

	// VGA image generator
	skyking_generator vga_image_generator(clk, rst_n, hsync, vsync, video_active, pix_x, pix_y, R, G, B);

	// BNC image generator
	bnc_demo bnc_image_generator(clk, rst_n, BNC_x, BNC_y, BNC_trig);

endmodule // tt_um_NicklausThompson_SkyKing

module bnc_demo(
	input wire clk, 
	input wire rst_n, 
	output wire [7:0] BNC_x,
	output wire [6:0] BNC_y, 
	output wire BNC_trig
);

	// Counter for timing
	reg [28:0] counter;
	always @(posedge clk) begin
		if (~rst_n) begin
			counter <= 0;
		end else begin
			counter <= counter + 1;
		end
	end

	assign BNC_x = counter[7:0];
	assign BNC_y = counter[14:8];
	assign BNC_trig = counter[5];

endmodule

module skyking_generator(
	input wire clk, 
	input wire rst_n,
	input wire hsync, 
	input wire vsync, 
	input wire video_active, 
	input wire [9:0] pix_x, 
	input wire [9:0] pix_y,
	output wire [1:0] R, 
	output wire [1:0] G, 
	output wire [1:0] B 
);

	// Counter for timing
	reg [28:0] counter;
	always @(posedge clk) begin
		if (~rst_n) begin
			counter <= 0;
		end else begin
			counter <= counter + 1;
		end
	end

	// Sky gradient
	wire [1:0] r_sky, g_sky;
	assign r_sky = {1'b1, ~&pix_y[8:7]};
	assign g_sky = ~pix_y[8:7];

	// Letters
	wire [17:0] do_letter;
	wire display_letter = |do_letter;
	// S
	assign do_letter[00] = (pix_y[8:3] == 6'b110100) & (pix_x[8:5] == 4'b0000)   & ~pix_x[9]
					   | (pix_y[8:4] == 5'b11010)  & (pix_x[8:3] == 6'b000000) & ~pix_x[9]
					   | (pix_y[8:3] == 6'b110110) & (pix_x[8:5] == 4'b0000)   & ~pix_x[9]
					   | (pix_y[8:4] == 5'b11011)  & (pix_x[8:3] == 6'b000011) & ~pix_x[9]
					   | (pix_y[8:3] == 6'b111000) & (pix_x[8:5] == 4'b0000)   & ~pix_x[9];
	// E
	assign do_letter[01] = (pix_y[8:3] == 6'b110100) & (pix_x[8:4] == 5'b00100)  & ~pix_x[9]
					   | (pix_y[8:3] == 6'b110100) & (pix_x[8:4] == 5'b00011)  & ~pix_x[9]
					   | (pix_y[8:3] == 6'b110110) & (pix_x[8:4] == 5'b00100)  & ~pix_x[9]
					   | (pix_y[8:3] == 6'b110110) & (pix_x[8:4] == 5'b00011)  & ~pix_x[9]
					   | (pix_y[8:3] == 6'b111000) & (pix_x[8:4] == 5'b00100)  & ~pix_x[9]
					   | (pix_y[8:3] == 6'b111000) & (pix_x[8:4] == 5'b00011)  & ~pix_x[9]
					   | (pix_y[8:5] == 4'b1101)   & (pix_x[8:3] == 6'b000110) & ~pix_x[9];
	// E
	assign do_letter[02] = (pix_y[8:3] == 6'b110100) & (pix_x[8:5] == 4'b00011)  & ~pix_x[9]
					   | (pix_y[8:3] == 6'b110110) & (pix_x[8:5] == 4'b00011)  & ~pix_x[9]
					   | (pix_y[8:3] == 6'b111000) & (pix_x[8:5] == 4'b00011)  & ~pix_x[9]
					   | (pix_y[8:5] == 4'b1101)   & (pix_x[8:3] == 6'b001100) & ~pix_x[9];
	// Y
	assign do_letter[03] = (pix_y[8:4] == 5'b11010)  & (pix_x[8:3] == 6'b010100) & ~pix_x[9]
					   | (pix_y[8:4] == 5'b11010)  & (pix_x[8:3] == 6'b010111);
	// O
	// U
	// S
	// P
	// A
	// C
	// E
	// C
	// O
	// W
	// B
	// O
	// Y
	// Cursor
	assign do_letter[17] = ((pix_y[8:3] == 6'b111000)  & pix_x[9] & (pix_x[8:4] == 5'b00101)
				         |  (pix_y[8:3] == 6'b111000)  & pix_x[9] & (pix_x[8:4] == 5'b00110))
				         & counter[22];

	// VGA color channels
	assign R = video_active ? r_sky | {2{display_letter}} : 2'b00;
	assign G = video_active ? g_sky | {2{display_letter}} : 2'b00;
	assign B = video_active ? {2{display_letter}} : 2'b00;

endmodule

