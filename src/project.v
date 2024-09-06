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
	assign BNC1_out = {BNC_x[4], BNC_x[6], BNC_y[4], BNC_y[6], BNC_x[5], BNC_x[7], BNC_y[5], BNC_trig};
	assign BNC2Y_out = {BNC_trig, BNC_y[5], BNC_y[3], BNC_y[1], BNC_y[6], BNC_y[4], BNC_y[2], BNC_y[0]};
	assign BNC2X_out = {BNC_x[7], BNC_x[5], BNC_x[3], BNC_x[1], BNC_x[6], BNC_x[4], BNC_x[2], BNC_x[0]};
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
	output reg [7:0] BNC_x,
	output reg [6:0] BNC_y, 
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
	
	always @(posedge clk) begin
		// 8-bit X output
		if (~rst_n) begin
			BNC_x <= 8'd0;
			BNC_y <= 7'd0;
		end
		
		case (counter[3:0])
			0: BNC_x <= 8'd150;
			1: BNC_x <= 8'd197;
			2: BNC_x <= 8'd232;
			3: BNC_x <= 8'd252;
			4: BNC_x <= 8'd252;
			5: BNC_x <= 8'd234;
			6: BNC_x <= 8'd199;
			7: BNC_x <= 8'd153;
			8: BNC_x <= 8'd103;
			9: BNC_x <= 8'd57;
			10: BNC_x <= 8'd21;
			11: BNC_x <= 8'd2;
			12: BNC_x <= 8'd2;
			13: BNC_x <= 8'd21;
			14: BNC_x <= 8'd56;
			15: BNC_x <= 8'd102;
			default: BNC_x <= 8'd0;
		endcase
		
		// 7-bit Y output
		case (counter[3:0])
			0: BNC_y <= 7'd126;
			1: BNC_y <= 7'd117;
			2: BNC_y <= 7'd99;
			3: BNC_y <= 7'd77;
			4: BNC_y <= 7'd52;
			5: BNC_y <= 7'd29;
			6: BNC_y <= 7'd11;
			7: BNC_y <= 7'd1;
			8: BNC_y <= 7'd1;
			9: BNC_y <= 7'd10;
			10: BNC_y <= 7'd27;
			11: BNC_y <= 7'd50;
			12: BNC_y <= 7'd75;
			13: BNC_y <= 7'd98;
			14: BNC_y <= 7'd116;
			15: BNC_y <= 7'd125;
			default: BNC_y <= 7'd0;
		endcase
	end

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
	assign do_letter[04] = 1'b0;
	// U
	assign do_letter[05] = 1'b0;
	// S
	assign do_letter[06] = 1'b0;
	// P
	assign do_letter[07] = 1'b0;
	// A
	assign do_letter[08] = 1'b0;
	// C
	assign do_letter[09] = 1'b0;
	// E
	assign do_letter[10] = 1'b0;
	// C
	assign do_letter[11] = 1'b0;
	// O
	assign do_letter[12] = 1'b0;
	// W
	assign do_letter[13] = 1'b0;
	// B
	assign do_letter[14] = 1'b0;
	// O
	assign do_letter[15] = 1'b0;
	// Y
	assign do_letter[16] = 1'b0;
	// Cursor
	assign do_letter[17] = ((pix_y[8:3] == 6'b111000)  & pix_x[9] & (pix_x[8:4] == 5'b00101)
				         |  (pix_y[8:3] == 6'b111000)  & pix_x[9] & (pix_x[8:4] == 5'b00110))
				         & counter[22];

	// VGA color channels
	assign R = video_active ? r_sky | {2{display_letter}} : 2'b00;
	assign G = video_active ? g_sky | {2{display_letter}} : 2'b00;
	assign B = video_active ? {2{display_letter}} : 2'b00;
	
	// Suppress unused signals warning
	wire _unused_ok = &{hsync, vsync};

endmodule

