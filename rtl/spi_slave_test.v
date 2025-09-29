`timescale 1ns/1ps
module spi_slave_test;
    // Signals
    reg clk, rst_n, spi_clk, spi_mosi, spi_cs_n;
    reg [7:0] tx_data;
    wire spi_miso, data_valid;
    wire [7:0] rx_data;
    
    // System clock
    always #10 clk = ~clk;
    
    // DUT
    spi_slave dut (
        .clk(clk), .rst_n(rst_n), .spi_clk(spi_clk), .spi_mosi(spi_mosi),
        .spi_miso(spi_miso), .spi_cs_n(spi_cs_n), .tx_data(tx_data),
        .rx_data(rx_data), .data_valid(data_valid)
    );
    
    // Test data pattern
    reg [7:0] test_pattern = 8'b10101010;
    integer bit_index;
    
    initial begin
        // Initialize
        clk = 0; rst_n = 0; spi_clk = 0; spi_mosi = 0; spi_cs_n = 1;
        tx_data = 8'h5A;
        bit_index = 7;
        
        // Setup simulation (comment out if not supported)
        // $dumpfile("spi_slave_test.vcd");
        // $dumpvars(0, spi_slave_test);
        
        $display("Starting SPI Slave Individual Test");
        
        // Reset
        #100 rst_n = 1;
        #100;
        
        // Simulate master transmission
        $display("Simulating master sending: 0x%02h", test_pattern);
        spi_cs_n = 0;
        #100;
        
        // Send 8 bits
        repeat(8) begin
            spi_mosi = test_pattern[bit_index];
            #50;
            spi_clk = 1;
            #100;
            spi_clk = 0;
            #50;
            bit_index = bit_index - 1;
        end
        
        spi_cs_n = 1;
        #100;
        
        $display("Slave Test Complete");
        $display("Master sent: 0x%02h", test_pattern);
        $display("Slave TX: 0x%02h", tx_data);
        $display("Slave RX: 0x%02h", rx_data);
        $display("Data Valid: %b", data_valid);
        
        if (rx_data == test_pattern && data_valid) begin
            $display("Result: PASS");
        end else begin
            $display("Result: FAIL");
        end
        
        $finish;
    end
endmodule