// =============================================================================
// 3. Top-level Module for FPGA Implementation
// =============================================================================
module spi_fpga_top (
    // System signals
    input wire clk_50mhz,     // 50MHz system clock
    input wire rst_n,         // Reset button (active low)
    
    // SPI Master interface (connect to Arduino or external device)
    output wire spi_clk_out,
    output wire spi_mosi_out,
    input wire spi_miso_in,
    output wire spi_cs_n_out,
    
    // SPI Slave interface (for testing)
    input wire spi_clk_in,
    input wire spi_mosi_in,
    output wire spi_miso_out,
    input wire spi_cs_n_in,
    
    // Control and status
    input wire [7:0] switches, // Input switches for data
    output wire [7:0] leds,    // Output LEDs for status
    input wire start_btn,      // Start transmission button
    
    // UART interface (for debugging)
    output wire uart_tx,
    input wire uart_rx
);

    // Internal signals
    wire clk;
    wire reset_n;
    reg start_pulse;
    reg start_btn_prev;
    wire [7:0] master_tx_data;
    wire [7:0] master_rx_data;
    wire master_tx_valid;
    wire [7:0] slave_tx_data;
    wire [7:0] slave_rx_data;
    wire slave_data_valid;
    
    // Clock and reset conditioning
    assign clk = clk_50mhz;
    assign reset_n = rst_n;
    
    // Input data from switches
    assign master_tx_data = switches;
    assign slave_tx_data = 8'hA5; // Fixed pattern for slave response
    
    // Output data to LEDs
    assign leds = master_rx_data;
    
    // Start button edge detection
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            start_btn_prev <= 0;
            start_pulse <= 0;
        end else begin
            start_btn_prev <= start_btn;
            start_pulse <= start_btn && !start_btn_prev;
        end
    end
    
    // SPI Master instance
    spi_master master_inst (
        .clk(clk),
        .rst_n(reset_n),
        .start(start_pulse),
        .tx_data(master_tx_data),
        .rx_data(master_rx_data),
        .tx_valid(master_tx_valid),
        .spi_clk(spi_clk_out),
        .spi_mosi(spi_mosi_out),
        .spi_miso(spi_miso_in),
        .spi_cs_n(spi_cs_n_out)
    );
    
    // SPI Slave instance (for loopback testing)
    spi_slave slave_inst (
        .clk(clk),
        .rst_n(reset_n),
        .spi_clk(spi_clk_in),
        .spi_mosi(spi_mosi_in),
        .spi_miso(spi_miso_out),
        .spi_cs_n(spi_cs_n_in),
        .tx_data(slave_tx_data),
        .rx_data(slave_rx_data),
        .data_valid(slave_data_valid)
    );
    
    // Simple UART for debugging (115200 baud)
    uart_debug uart_inst (
        .clk(clk),
        .rst_n(reset_n),
        .tx_data({master_tx_data, master_rx_data}), // Send both TX and RX data
        .tx_start(master_tx_valid),
        .uart_tx(uart_tx)
    );
    
endmodule
