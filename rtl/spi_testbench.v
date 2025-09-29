// =============================================================================
// ModelSim 10.1d Compatible SPI Testbench
// Fixed for older ModelSim versions without join_none support
// =============================================================================

`timescale 1ns/1ps

module spi_testbench;

    // System signals
    reg clk;
    reg rst_n;
    
    // SPI Master signals
    reg start;
    reg [7:0] tx_data;
    wire [7:0] master_rx_data;
    wire master_tx_valid;
    wire spi_clk;
    wire spi_mosi;
    wire spi_miso;
    wire spi_cs_n;
    
    // SPI Slave signals
    reg [7:0] slave_tx_data;
    wire [7:0] slave_rx_data;
    wire slave_data_valid;
    
    // Test variables
    integer test_count = 0;
    integer error_count = 0;
    
    // Clock generation (50MHz)
    always #10 clk = ~clk;
    
    // DUT instantiation
    spi_master master_dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .rx_data(master_rx_data),
        .tx_valid(master_tx_valid),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n)
    );
    
    spi_slave slave_dut (
        .clk(clk),
        .rst_n(rst_n),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),
        .tx_data(slave_tx_data),
        .rx_data(slave_rx_data),
        .data_valid(slave_data_valid)
    );
    
    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        start = 0;
        tx_data = 8'h00;
        slave_tx_data = 8'h00;
        
        // Setup waveform dump (comment out if not supported)
        // $dumpfile("spi_simulation.vcd");
        // $dumpvars(0, spi_testbench);
        
        // Print test header
        $display("=================================================");
        $display("SPI Protocol Testbench Starting");
        $display("Time: %0t", $time);
        $display("=================================================");
        
        // Reset sequence
        #100;
        rst_n = 1;
        #100;
        
        // Test Case 1: Basic SPI transmission
        test_spi_transmission(8'h55, 8'hAA, "Basic Transmission Test");
        
        // Test Case 2: Multiple sequential transmissions
        test_spi_transmission(8'h01, 8'hFE, "Sequential Test 1");
        test_spi_transmission(8'h02, 8'hFD, "Sequential Test 2");
        test_spi_transmission(8'h04, 8'hFB, "Sequential Test 3");
        
        // Test Case 3: Edge cases
        test_spi_transmission(8'h00, 8'hFF, "All Zeros to All Ones");
        test_spi_transmission(8'hFF, 8'h00, "All Ones to All Zeros");
        test_spi_transmission(8'hA5, 8'h5A, "Pattern Test 1");
        test_spi_transmission(8'h3C, 8'hC3, "Pattern Test 2");
        
        // Test Case 4: Rapid fire test
        rapid_fire_test();
        
        // Wait for final transaction to complete
        #10000;
        
        // Print test summary
        $display("=================================================");
        $display("SPI Protocol Testbench Complete");
        $display("Total Tests: %0d", test_count);
        $display("Errors: %0d", error_count);
        if (error_count == 0) 
            $display("Result: PASS - All tests passed!");
        else 
            $display("Result: FAIL - %0d tests failed!", error_count);
        $display("=================================================");
        
        $finish;
    end
    
    // Task: Test SPI transmission
    task test_spi_transmission;
        input [7:0] master_data;
        input [7:0] slave_data;
        input [200*8:1] test_name;
        begin
            test_count = test_count + 1;
            $display("\n--- Test %0d: %0s ---", test_count, test_name);
            $display("Time: %0t", $time);
            
            // Setup test data
            tx_data = master_data;
            slave_tx_data = slave_data;
            
            $display("Master TX: 0x%02h, Slave TX: 0x%02h", master_data, slave_data);
            
            // Start transmission
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait for transmission to complete
            wait(master_tx_valid == 1);
            @(posedge clk);
            
            // Check results
            $display("Master RX: 0x%02h, Slave RX: 0x%02h", master_rx_data, slave_rx_data);
            
            // Verify data integrity
            if (master_rx_data == slave_data && slave_rx_data == master_data) begin
                $display("Result: PASS");
            end else begin
                $display("Result: FAIL");
                $display("Expected - Master RX: 0x%02h, Slave RX: 0x%02h", slave_data, master_data);
                error_count = error_count + 1;
            end
            
            // Wait before next test
            #1000;
        end
    endtask
    
    // Task: Rapid fire test
    task rapid_fire_test;
        integer i;
        begin
            $display("\n--- Rapid Fire Test ---");
            $display("Performing 8 rapid sequential transmissions...");
            
            for (i = 0; i < 8; i = i + 1) begin
                test_count = test_count + 1;
                tx_data = i * 16 + i;
                slave_tx_data = 8'hFF - (i * 16 + i);
                
                @(posedge clk);
                start = 1;
                @(posedge clk);
                start = 0;
                
                wait(master_tx_valid == 1);
                @(posedge clk);
                
                if (master_rx_data == slave_tx_data && slave_rx_data == tx_data) begin
                    $display("Rapid test %0d: PASS (TX:0x%02h RX:0x%02h)", 
                             i+1, tx_data, master_rx_data);
                end else begin
                    $display("Rapid test %0d: FAIL (TX:0x%02h RX:0x%02h Expected:0x%02h)", 
                             i+1, tx_data, master_rx_data, slave_tx_data);
                    error_count = error_count + 1;
                end
                
                #200; // Short delay between rapid transmissions
            end
        end
    endtask
    
    // Monitor SPI signals for debugging
    always @(posedge spi_clk or negedge spi_cs_n) begin
        if (!spi_cs_n && spi_clk) begin
            $display("SPI Activity - Time:%0t CS:%b CLK:%b MOSI:%b MISO:%b", 
                     $time, spi_cs_n, spi_clk, spi_mosi, spi_miso);
        end
    end
    
    // Timeout watchdog
    initial begin
        #500000; // 500us timeout
        $display("ERROR: Simulation timeout!");
        $display("Test may be stuck. Check your design.");
        $finish;
    end

endmodule
