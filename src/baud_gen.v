module baud_gen #(parameter DIVISOR = 434)(
    input  wire clk,
    output reg  tick
);
  reg [15:0] counter = 0;
  always @(posedge clk) begin
    if (counter == DIVISOR-1) begin
      counter <= 0;
      tick    <= 1'b1;
    end else begin
      counter <= counter + 1;
      tick    <= 1'b0;
    end
  end
endmodule
