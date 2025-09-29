library verilog;
use verilog.vl_types.all;
entity spi_fpga_top is
    port(
        clk_50mhz       : in     vl_logic;
        rst_n           : in     vl_logic;
        spi_clk_out     : out    vl_logic;
        spi_mosi_out    : out    vl_logic;
        spi_miso_in     : in     vl_logic;
        spi_cs_n_out    : out    vl_logic;
        spi_clk_in      : in     vl_logic;
        spi_mosi_in     : in     vl_logic;
        spi_miso_out    : out    vl_logic;
        spi_cs_n_in     : in     vl_logic;
        switches        : in     vl_logic_vector(7 downto 0);
        leds            : out    vl_logic_vector(7 downto 0);
        start_btn       : in     vl_logic;
        uart_tx         : out    vl_logic;
        uart_rx         : in     vl_logic
    );
end spi_fpga_top;
