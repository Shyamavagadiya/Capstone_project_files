// Top-Level Module for EP2C5T144 FPGA Board
module fpga_spi_top (
    // Clock and Reset
    input wire clk_50mhz,     // PIN_17 (CLK0) - 50MHz system clock
    input wire reset_n,       // PIN_144 - Reset button (active low)
    
    // UART Interface (connect to USB-UART adaptor)
    input wire uart_rx,       // PIN_143 - Connect to USB-UART TX
    output wire uart_tx,      // PIN_142 - Connect to USB-UART RX
    
    // SPI Interface (connect to Arduino)
    output wire spi_sclk,     // PIN_141 - Connect to Arduino Pin 13 (SCK)
    output wire spi_mosi,     // PIN_139 - Connect to Arduino Pin 11 (MOSI)
    input wire spi_miso,      // PIN_137 - Connect to Arduino Pin 12 (MISO)
    output wire spi_ss        // PIN_136 - Connect to Arduino Pin 10 (SS)
);

// Internal signals
wire reset = ~reset_n;
wire [7:0] uart_rx_data;
wire uart_rx_valid;
wire [7:0] uart_tx_data;
wire uart_tx_ready;
wire uart_tx_start;

wire [7:0] spi_tx_data;
wire [7:0] spi_rx_data;
wire spi_start;
wire spi_done;

// UART Controller Instance
uart_controller uart_inst (
    .clk(clk_50mhz),
    .reset(reset),
    .rx(uart_rx),
    .tx(uart_tx),
    .rx_data(uart_rx_data),
    .rx_valid(uart_rx_valid),
    .tx_data(uart_tx_data),
    .tx_start(uart_tx_start),
    .tx_ready(uart_tx_ready)
);

// SPI Master Instance
spi_master spi_inst (
    .clk(clk_50mhz),
    .reset(reset),
    .tx_data(spi_tx_data),
    .start_tx(spi_start),
    .rx_data(spi_rx_data),
    .tx_done(spi_done),
    .sclk(spi_sclk),
    .mosi(spi_mosi),
    .miso(spi_miso),
    .ss(spi_ss)
);

// Control Logic
assign spi_tx_data = uart_rx_data;
assign spi_start = uart_rx_valid;
assign uart_tx_data = uart_rx_data + 1;
assign uart_tx_start = uart_rx_valid;

endmodule

// SPI Master Module
module spi_master (
    input wire clk,
    input wire reset,
    input wire [7:0] tx_data,
    input wire start_tx,
    output reg [7:0] rx_data,
    output reg tx_done,
    output reg sclk,
    output reg mosi,
    input wire miso,
    output reg ss
);

parameter IDLE = 2'b00, TRANSMIT = 2'b01, DONE = 2'b10;
parameter CLK_DIV = 250; // SPI clock = 50MHz/250 = 200KHz

reg [1:0] state;
reg [3:0] bit_count;
reg [7:0] tx_buffer;
reg [7:0] rx_buffer;
reg [8:0] clk_div_counter; // Increased to 9 bits for larger division

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        sclk <= 0;
        mosi <= 0;
        ss <= 1;
        tx_done <= 0;
        bit_count <= 0;
        clk_div_counter <= 0;
        rx_data <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                ss <= 1;
                sclk <= 0;
                tx_done <= 0;
                if (start_tx) begin
                    tx_buffer <= tx_data;
                    bit_count <= 7;
                    state <= TRANSMIT;
                    ss <= 0;
                    clk_div_counter <= 0;
                end
            end
            
            TRANSMIT: begin
                if (clk_div_counter < CLK_DIV/2) begin
                    clk_div_counter <= clk_div_counter + 1;
                end else begin
                    clk_div_counter <= 0;
                    sclk <= ~sclk;
                    
                    if (sclk == 0) begin // Rising edge
                        mosi <= tx_buffer[bit_count];
                    end else begin // Falling edge
                        rx_buffer[bit_count] <= miso;
                        if (bit_count == 0) begin
                            state <= DONE;
                        end else begin
                            bit_count <= bit_count - 1;
                        end
                    end
                end
            end
            
            DONE: begin
                ss <= 1;
                sclk <= 0;
                rx_data <= rx_buffer;
                tx_done <= 1;
                state <= IDLE;
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule

// Simple UART Controller
module uart_controller (
    input wire clk,
    input wire reset,
    input wire rx,
    output wire tx,
    output reg [7:0] rx_data,
    output reg rx_valid,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx_ready
);

parameter BAUD_DIV = 434; // 50MHz / 115200 ≈ 434

// UART RX
reg [3:0] rx_state;
reg [7:0] rx_shift;
reg [3:0] rx_bit_count;
reg [8:0] rx_baud_count;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        rx_state <= 0;
        rx_valid <= 0;
        rx_baud_count <= 0;
        rx_data <= 8'h00;
    end else begin
        rx_valid <= 0;
        case (rx_state)
            0: begin // Wait for start bit
                if (rx == 0) begin
                    rx_state <= 1;
                    rx_baud_count <= BAUD_DIV/2;
                end
            end
            1: begin // Sample start bit
                if (rx_baud_count == 0) begin
                    rx_state <= 2;
                    rx_bit_count <= 0;
                    rx_baud_count <= BAUD_DIV;
                end else begin
                    rx_baud_count <= rx_baud_count - 1;
                end
            end
            2: begin // Receive data bits
                if (rx_baud_count == 0) begin
                    rx_shift[rx_bit_count] <= rx;
                    rx_bit_count <= rx_bit_count + 1;
                    rx_baud_count <= BAUD_DIV;
                    if (rx_bit_count == 7) begin
                        rx_state <= 3;
                    end
                end else begin
                    rx_baud_count <= rx_baud_count - 1;
                end
            end
            3: begin // Stop bit
                if (rx_baud_count == 0) begin
                    rx_data <= rx_shift;
                    rx_valid <= 1;
                    rx_state <= 0;
                end else begin
                    rx_baud_count <= rx_baud_count - 1;
                end
            end
            default: rx_state <= 0;
        endcase
    end
end

// UART TX
reg [3:0] tx_state;
reg [7:0] tx_shift;
reg [3:0] tx_bit_count;
reg [8:0] tx_baud_count;
reg tx_reg;

assign tx = tx_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        tx_state <= 0;
        tx_ready <= 1;
        tx_reg <= 1;
    end else begin
        case (tx_state)
            0: begin // Idle
                tx_reg <= 1;
                if (tx_start && tx_ready) begin
                    tx_shift <= tx_data;
                    tx_state <= 1;
                    tx_ready <= 0;
                    tx_baud_count <= BAUD_DIV;
                end
            end
            1: begin // Start bit
                tx_reg <= 0;
                if (tx_baud_count == 0) begin
                    tx_state <= 2;
                    tx_bit_count <= 0;
                    tx_baud_count <= BAUD_DIV;
                end else begin
                    tx_baud_count <= tx_baud_count - 1;
                end
            end
            2: begin // Data bits
                tx_reg <= tx_shift[tx_bit_count];
                if (tx_baud_count == 0) begin
                    tx_bit_count <= tx_bit_count + 1;
                    tx_baud_count <= BAUD_DIV;
                    if (tx_bit_count == 7) begin
                        tx_state <= 3;
                    end
                end else begin
                    tx_baud_count <= tx_baud_count - 1;
                end
            end
            3: begin // Stop bit
                tx_reg <= 1;
                if (tx_baud_count == 0) begin
                    tx_state <= 0;
                    tx_ready <= 1;
                end else begin
                    tx_baud_count <= tx_baud_count - 1;
                end
            end
            default: tx_state <= 0;
        endcase
    end
end

endmodule
