module pwm
  #(
      parameter MAX_WIDTH_BITDEPTH = 32
  )
  (
    input clk,
    input [MAX_WIDTH_BITDEPTH-1:0] width,
                        // pulse width of the active part of the duty cycle
                        //   (in clk ticks)
    input [MAX_WIDTH_BITDEPTH-1:0] period,
                        // full width of the duty cycle (in clk ticks)
    output q
  );

  reg [MAX_WIDTH_BITDEPTH-1:0] counter;

  always @(posedge clk) begin
    if (counter == (period-1)) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  assign q = (counter < width);

endmodule
