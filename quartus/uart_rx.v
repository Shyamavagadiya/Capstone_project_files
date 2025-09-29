module uart_rx (
    input clk,            // system clock
    input reset,          // reset signal
    input rx,             // UART receive line
    output reg [7:0] rx_data, // received data
    output reg rx_done    // reception complete flag
);

    parameter CLK_FREQ = 50000000;   // 50 MHz FPGA clock
    parameter BAUD_RATE = 9600;      // UART baud rate
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [15:0] clk_count;
    reg [3:0] bit_index;
    reg [7:0] rx_shift;
    reg busy;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_done <= 0;
            clk_count <= 0;
            bit_index <= 0;
            busy <= 0;
        end else begin
            if (!busy && !rx) begin  // start bit detected
                busy <= 1;
                clk_count <= CLKS_PER_BIT/2;
                bit_index <= 0;
                rx_done <= 0;
            end else if (busy) begin
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    if (bit_index < 8) begin
                        rx_shift[bit_index] <= rx;
                        bit_index <= bit_index + 1;
                    end else begin
                        rx_data <= rx_shift;
                        rx_done <= 1;
                        busy <= 0;
                    end
                end
            end
        end
    end
endmodule
