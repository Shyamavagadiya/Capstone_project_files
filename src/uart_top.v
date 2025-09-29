module top_uart(
    input  wire clk,          // FPGA clock
    input  wire rx_pin,       // UART RX from PC
    output wire tx_pin,       // UART TX to PC
    output wire [7:0] leds    // Display received byte
);

  wire       tx_active, tx_done, rx_dv;
  wire [7:0] rx_byte;
  reg        tx_dv = 0;
  reg  [7:0] tx_byte;

  // Instantiate UART TX
  uart_tx #(434) tx_inst (
    .i_clk(clk),
    .i_tx_dv(tx_dv),
    .i_tx_byte(tx_byte),
    .o_tx_active(tx_active),
    .o_tx_serial(tx_pin),
    .o_tx_done(tx_done)
  );

  // Instantiate UART RX
  uart_rx #(434) rx_inst (
    .i_clk(clk),
    .i_rx_serial(rx_pin),
    .o_rx_dv(rx_dv),
    .o_rx_byte(rx_byte)
  );

  assign leds = rx_byte;

endmodule
