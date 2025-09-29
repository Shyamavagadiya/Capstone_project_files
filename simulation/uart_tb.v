`timescale 1ns/1ps
module uart_tb();

  reg        clk   = 0;
  reg        tx_dv = 0;
  reg  [7:0] tx_byte;
  wire       tx_active, tx_serial, tx_done;
  wire       rx_dv;
  wire [7:0] rx_byte;

  // clock
  always #10 clk = ~clk; // 50MHz clock

  // Instantiate TX
  uart_tx #(434) tx_inst (
    .i_clk(clk),
    .i_tx_dv(tx_dv),
    .i_tx_byte(tx_byte),
    .o_tx_active(tx_active),
    .o_tx_serial(tx_serial),
    .o_tx_done(tx_done)
  );

  // Instantiate RX
  uart_rx #(434) rx_inst (
    .i_clk(clk),
    .i_rx_serial(tx_serial),
    .o_rx_dv(rx_dv),
    .o_rx_byte(rx_byte)
  );

  initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);

    #100;
    tx_byte = 8'hAB;
    tx_dv   = 1'b1;
    #20;
    tx_dv   = 1'b0;

    wait(rx_dv == 1'b1);
    $display("Received Byte: %h", rx_byte);

    #1000;
    $finish;
  end
endmodule
