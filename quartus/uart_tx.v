module uart_tx (
    input clk,            // system clock
    input reset,          // reset signal
    input tx_start,       // start transmission
    input [7:0] tx_data,  // data to transmit
    output reg tx,        // UART transmit line
    output reg busy       // indicates if transmitter is busy
);

    parameter CLK_FREQ = 50000000;   // 50 MHz FPGA clock
    parameter BAUD_RATE = 9600;      // UART baud rate
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [15:0] clk_count;
    reg [3:0] bit_index;
    reg [9:0] tx_shift;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx <= 1'b1;
            busy <= 0;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift <= 10'b1111111111;
        end else begin
            if (tx_start && !busy) begin
                busy <= 1;
                tx_shift <= {1'b1, tx_data, 1'b0}; // stop, data, start
                clk_count <= 0;
                bit_index <= 0;
            end else if (busy) begin
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    tx <= tx_shift[0];
                    tx_shift <= tx_shift >> 1;
                    if (bit_index < 9)
                        bit_index <= bit_index + 1;
                    else
                        busy <= 0;
                end
            end
        end
    end
endmodule
