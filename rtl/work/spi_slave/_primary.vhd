library verilog;
use verilog.vl_types.all;
entity spi_slave is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        spi_clk         : in     vl_logic;
        spi_mosi        : in     vl_logic;
        spi_miso        : out    vl_logic;
        spi_cs_n        : in     vl_logic;
        tx_data         : in     vl_logic_vector(7 downto 0);
        rx_data         : out    vl_logic_vector(7 downto 0);
        data_valid      : out    vl_logic
    );
end spi_slave;
