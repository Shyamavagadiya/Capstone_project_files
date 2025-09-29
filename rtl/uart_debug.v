// =============================================================================
// 4. Simple UART Module for Debugging
// =============================================================================
module uart_debug (
    input wire clk,
    input wire rst_n,
    input wire [15:0] tx_data,
    input wire tx_start,
    output reg uart_tx
);

    // UART parameters for 115200 baud @ 50MHz
    parameter BAUD_DIV = 434; // 50MHz / 115200
    
    // State machine
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    
    reg [1:0] state;
    reg [15:0] shift_reg;
    reg [4:0] bit_count;
    reg [8:0] baud_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            uart_tx <= 1;
            shift_reg <= 0;
            bit_count <= 0;
            baud_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    uart_tx <= 1;
                    if (tx_start) begin
                        state <= START;
                        shift_reg <= tx_data;
                        bit_count <= 0;
                        baud_count <= 0;
                    end
                end
                
                START: begin
                    uart_tx <= 0; // Start bit
                    if (baud_count == BAUD_DIV-1) begin
                        baud_count <= 0;
                        state <= DATA;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end
                
                DATA: begin
                    uart_tx <= shift_reg[0];
                    if (baud_count == BAUD_DIV-1) begin
                        baud_count <= 0;
                        shift_reg <= {1'b0, shift_reg[15:1]};
                        bit_count <= bit_count + 1;
                        if (bit_count == 15) begin
                            state <= STOP;
                        end
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end
                
                STOP: begin
                    uart_tx <= 1; // Stop bit
                    if (baud_count == BAUD_DIV-1) begin
                        baud_count <= 0;
                        state <= IDLE;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end
            endcase
        end
    end
endmodule
