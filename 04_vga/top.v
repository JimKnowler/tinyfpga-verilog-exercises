// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU, // USB pull-up resistor
    output PIN_11,  // RED
    output PIN_12,  // GREEN
    output PIN_13,  // BLUE
    output PIN_9,   // V-Sync
    output PIN_10   // H-Sync
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // turn on the LED
    assign LED = 1;

    ////////
    // Basic VGA Output Circuit
    ////////

    // Generate a 40 MHz internal clock from 16 MHz input clock
    // - generated with icepll -16 -o 40
    wire clk_40;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0000),		    // DIVR =  0
        .DIVF(7'b0100111),	  // DIVF = 39
        .DIVQ(3'b100),		    // DIVQ =  4
        .FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
    ) pll (
        .REFERENCECLK(CLK),
        .PLLOUTCORE(clk_40),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );

    // generate VGA 800x600, 60Hz
    // taken from: http://martin.hinner.info/vga/timing.html
    localparam H_ACTIVE_VIDEO = 800;
    localparam H_FRONT_PORCH = 40;
    localparam H_SYNC_PULSE = 128;
    localparam H_BACK_PORCH = 88;
    localparam V_ACTIVE_VIDEO = 600;
    localparam V_FRONT_PORCH = 1;
    localparam V_SYNC_PULSE = 4;
    localparam V_BACK_PORCH = 23;

    // intermediate calculations
    localparam H_SYNC_PULSE_START = H_ACTIVE_VIDEO + H_FRONT_PORCH;
    localparam H_SYNC_PULSE_END = H_SYNC_PULSE_START + H_SYNC_PULSE;
    localparam H_END_MINUS_1 = H_SYNC_PULSE_END + H_BACK_PORCH - 1;

    localparam V_SYNC_PULSE_START = V_ACTIVE_VIDEO + V_FRONT_PORCH;
    localparam V_SYNC_PULSE_END = V_SYNC_PULSE_START + V_SYNC_PULSE;
    localparam V_END_MINUS_1 = V_SYNC_PULSE_END + V_BACK_PORCH - 1;

    // horizontal and vertical positions
    reg [10:0] h_counter;
    reg [10:0] v_counter;

    // signals for whether currently in active area of h / v
    wire is_h_active_video;
    assign is_h_active_video = (h_counter < H_ACTIVE_VIDEO);

    wire is_v_active_video;
    assign is_v_active_video = (v_counter < V_ACTIVE_VIDEO);

    // signals for whether sync is pulsing
    wire is_h_sync_pulse;
    assign is_h_sync_pulse = (h_counter >= H_SYNC_PULSE_START) && (h_counter < H_SYNC_PULSE_END);

    wire is_v_sync_pulse;
    assign is_v_sync_pulse = (v_counter >= V_SYNC_PULSE_START) && (v_counter < V_SYNC_PULSE_END);

    // x,y co-ords of current pixel to draw
    wire [9:0] x;
    wire [9:0] y;

    assign x[9:0] = is_h_active_video ? h_counter[9:0] : 0;
    assign y[9:0] = is_v_active_video ? v_counter[9:0] : 0;

    wire is_active_video;
    assign is_active_video = is_h_active_video && is_v_active_video;

    // sequential logic for rendering
    always @(posedge clk_40) begin
      // beware of off-by-one errors when comparing to H_END / V_END
      if (h_counter == H_END_MINUS_1) begin
        h_counter <= 0;

        if (v_counter == V_END_MINUS_1) begin
          v_counter <= 0;
        end else begin
          v_counter <= v_counter + 1;
        end

      end else begin
        h_counter <= h_counter + 1;
      end
    end

    // generate output
    assign PIN_10 = is_h_sync_pulse;      // h sync
    assign PIN_9 = is_v_sync_pulse;       // v sync

    wire red;
    wire green;
    wire blue;

    assign red = x < 400;
    assign blue = y < 300;
    assign green = x >= 400;

    assign PIN_11 = is_active_video && red;    // red
    assign PIN_12 = is_active_video && green;  // green
    assign PIN_13 = is_active_video && blue;   // blue


endmodule
