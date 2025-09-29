// =============================================================================
// 1. SPI Master Module
// =============================================================================
module spi_master (
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire start,         // Start transmission
    input wire [7:0] tx_data, // Data to transmit
    output reg [7:0] rx_data, // Received data
    output reg tx_valid,      // Transmission complete flag
    output reg spi_clk,       // SPI clock
    output reg spi_mosi,      // Master Out Slave In
    input wire spi_miso,      // Master In Slave Out
    output reg spi_cs_n       // Chip Select (active low)
);

    // Parameters
    parameter CLK_DIV = 4;    // Clock divider for SPI clock
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    localparam DONE = 2'b10;
    
    // Internal signals
    reg [1:0] state;
    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_counter;
    reg [2:0] clk_counter;
    reg spi_clk_en;
    
    // Clock generation for SPI
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 0;
            spi_clk <= 0;
            spi_clk_en <= 0;
        end else begin
            if (state == ACTIVE) begin
                clk_counter <= clk_counter + 1;
                if (clk_counter == CLK_DIV-1) begin
                    clk_counter <= 0;
                    spi_clk <= ~spi_clk;
                    spi_clk_en <= 1;
                end else begin
                    spi_clk_en <= 0;
                end
            end else begin
                clk_counter <= 0;
                spi_clk <= 0;
                spi_clk_en <= 0;
            end
        end
    end
    
    // Main SPI state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_counter <= 0;
            spi_cs_n <= 1;
            spi_mosi <= 0;
            tx_valid <= 0;
            rx_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_valid <= 0;
                    spi_cs_n <= 1;
                    if (start) begin
                        state <= ACTIVE;
                        tx_shift_reg <= tx_data;
                        bit_counter <= 0;
                        spi_cs_n <= 0;
                        spi_mosi <= tx_data[7];
                    end
                end
                
                ACTIVE: begin
                    if (spi_clk_en && spi_clk) begin // Rising edge of SPI clock
                        // Shift out next bit
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter < 7)
                            spi_mosi <= tx_shift_reg[6];
                    end else if (spi_clk_en && !spi_clk) begin // Falling edge of SPI clock
                        // Sample MISO
                        rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                        if (bit_counter == 8) begin
                            state <= DONE;
                            rx_data <= {rx_shift_reg[6:0], spi_miso};
                        end
                    end
                end
                
                DONE: begin
                    spi_cs_n <= 1;
                    tx_valid <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

