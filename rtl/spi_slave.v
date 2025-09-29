// =============================================================================
// 2. SPI Slave Module
// =============================================================================
module spi_slave (
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire spi_clk,       // SPI clock from master
    input wire spi_mosi,      // Master Out Slave In
    output reg spi_miso,      // Master In Slave Out
    input wire spi_cs_n,      // Chip Select (active low)
    input wire [7:0] tx_data, // Data to transmit
    output reg [7:0] rx_data, // Received data
    output reg data_valid     // Data received flag
);

    // Internal signals
    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_counter;
    reg spi_clk_prev;
    reg cs_n_prev;
    
    // Edge detection
    wire spi_clk_rising = spi_clk && !spi_clk_prev;
    wire spi_clk_falling = !spi_clk && spi_clk_prev;
    wire cs_falling = !spi_cs_n && cs_n_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_counter <= 0;
            spi_miso <= 0;
            rx_data <= 0;
            data_valid <= 0;
            spi_clk_prev <= 0;
            cs_n_prev <= 1;
        end else begin
            spi_clk_prev <= spi_clk;
            cs_n_prev <= spi_cs_n;
            
            if (cs_falling) begin
                // Start of new transaction
                tx_shift_reg <= tx_data;
                bit_counter <= 0;
                data_valid <= 0;
                spi_miso <= tx_data[7];
            end else if (!spi_cs_n) begin
                if (spi_clk_rising) begin
                    // Sample MOSI on rising edge
                    rx_shift_reg <= {rx_shift_reg[6:0], spi_mosi};
                    bit_counter <= bit_counter + 1;
                end else if (spi_clk_falling) begin
                    // Shift out data on falling edge
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    if (bit_counter < 8)
                        spi_miso <= tx_shift_reg[6];
                    
                    if (bit_counter == 8) begin
                        rx_data <= rx_shift_reg;
                        data_valid <= 1;
                    end
                end
            end else begin
                spi_miso <= 1'bz; // High impedance when not selected
                data_valid <= 0;
            end
        end
    end
endmodule

