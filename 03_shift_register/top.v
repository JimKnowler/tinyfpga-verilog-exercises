// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    input PIN_15,   // RESET button
    input PIN_14,   // SHIFT button
    output PIN_11,  // LED 1
    output PIN_12,  // LED 2
    output PIN_13,  // LED 3
    output LED,   // User/boot LED next to power LED
    output USBPU  // USB pull-up resistor
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // ready for for loop
    integer i;

    // human readable
    wire RESET_BUTTON = PIN_15;
    wire SHIFT_BUTTON = PIN_14;
    wire LED_0 = PIN_11;
    wire LED_1 = PIN_12;
    wire LED_2 = PIN_13;

    ////////
    // shift/rotate a single value through a shift register
    ////////

    // clock clock_divider
    reg [20:0] clock_divider;

    reg clock_led;

    // current values in shift register
    reg [2:0] blink_counter;

    // pattern that will be injected into the shift register when reset
    wire [2:0] reset_pattern = 3'b100;

    // divide the clock
    always @(posedge CLK) begin
        clock_divider <= clock_divider + 1;

        if (1 == &clock_divider) begin
          clock_led = ~clock_led;
        end
    end

    always @(posedge clock_led) begin
      if (RESET_BUTTON) begin
        blink_counter <= reset_pattern;
      end else if(SHIFT_BUTTON) begin
        for (i=0; i<3; i = i + 1) begin
          blink_counter[ (i+1) % 3 ] <= blink_counter[ i ];
        end
      end
    end

    // light up the LEDs according to the shift pattern
    assign PIN_11 = blink_counter[0];
    assign PIN_12 = blink_counter[1];
    assign PIN_13 = blink_counter[2];

    // light up LED using clock_divider
    assign LED = clock_led;

endmodule
