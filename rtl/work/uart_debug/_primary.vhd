library verilog;
use verilog.vl_types.all;
entity uart_debug is
    generic(
        BAUD_DIV        : integer := 434
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        tx_data         : in     vl_logic_vector(15 downto 0);
        tx_start        : in     vl_logic;
        uart_tx         : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of BAUD_DIV : constant is 1;
end uart_debug;
