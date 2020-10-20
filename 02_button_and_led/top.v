// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,
    input PIN_14,
    output LED,
    output USBPU  // USB pull up resistor
);
    // drive USB pull-up register to '0' to disable USBz
    assign USBPU = 0;

    reg [23:0] counter;         // divide clock down to half a second
    reg active;

    always @(posedge CLK) begin
      if (1 == &counter) begin
        active <= ~active;      // invert active, every half a second
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end

    assign LED = PIN_14 & active;        // use onboard LED to preview 'active'
endmodule
