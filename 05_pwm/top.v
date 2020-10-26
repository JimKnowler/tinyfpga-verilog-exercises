// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,      // 16MHz clock
    output LED,     // User/boot LED next to power LED
    output USBPU,   // USB pull-up resistor
    input PIN_10,   // BUTTON 1
    input PIN_11,   // BUTTON 2
    output PIN_14,  // LED PWM
    output PIN_15,  // LED PWM
    output PIN_16   // SERVO PWM
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // turn on the default LED on TinyFPGA-Bx
    assign LED = 1;

    ////////
    // Pulse Width Modulation test app
    ////////

    // ticks in 16Mhz clock
    localparam NUM_TICKS_1MS = 16000;

    // Sero has clock period of 20milliseconds
    wire [18:0] NUM_TICKS_20MS;
    assign NUM_TICKS_20MS[18:0] = 320000;

    // clock divider - to control rate
    reg [9:0] counter;

    // control pulse_width between 0 and 1ms
    reg [18:0] pulse_width;

    always @(posedge CLK) begin
      // use counter to divide the clock
      counter <= counter + 1;

      // on the divided clock
      if (0 == counter) begin
        // use button 1 to increase brightness
        if (PIN_10) begin
          if (pulse_width < NUM_TICKS_1MS)
            pulse_width <= pulse_width + 1;
        end

        // use button 2 to decrease brightness
        if (PIN_11) begin
          if (pulse_width > 0)
            pulse_width <= pulse_width - 1;
        end
      end
    end

    wire pwm1_q;

    // we want pulse width to be in range of 1~2ms, so we
    // add add a 1ms offset to our pulse_width in range of 0~1ms
    wire [18:0] pulse_width_offset;
    assign pulse_width_offset = NUM_TICKS_1MS;

    wire [18:0] pulse_width_plus_offset;
    assign pulse_width_plus_offset = pulse_width_offset[14:0] + pulse_width[14:0];

    pwm #(.MAX_WIDTH_BITDEPTH(19)) pwm_instance(
      .clk(CLK),
      .width(pulse_width_plus_offset[18:0]),
      .period(NUM_TICKS_20MS[18:0]),
      .q(pwm1_q)
      );

    // LED PWM
    assign PIN_14 = pwm1_q;
    assign PIN_15 = 0;

    // SERVO PWM control
    assign PIN_16 = pwm1_q;


endmodule
