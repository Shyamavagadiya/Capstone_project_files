# Timing constraints for FPGA SPI project
create_clock -name "clk_50mhz" -period 20.000 [get_ports {clk_50mhz}]

# Set input delays
set_input_delay -clock clk_50mhz -max 5.0 [get_ports uart_rx]
set_input_delay -clock clk_50mhz -min 0.0 [get_ports uart_rx]
set_input_delay -clock clk_50mhz -max 5.0 [get_ports spi_miso]
set_input_delay -clock clk_50mhz -min 0.0 [get_ports spi_miso]
set_input_delay -clock clk_50mhz -max 5.0 [get_ports reset_n]
set_input_delay -clock clk_50mhz -min 0.0 [get_ports reset_n]

# Set output delays
set_output_delay -clock clk_50mhz -max 5.0 [get_ports uart_tx]
set_output_delay -clock clk_50mhz -min 0.0 [get_ports uart_tx]
set_output_delay -clock clk_50mhz -max 5.0 [get_ports spi_sclk]
set_output_delay -clock clk_50mhz -min 0.0 [get_ports spi_sclk]
set_output_delay -clock clk_50mhz -max 5.0 [get_ports spi_mosi]
set_output_delay -clock clk_50mhz -min 0.0 [get_ports spi_mosi]
set_output_delay -clock clk_50mhz -max 5.0 [get_ports spi_ss]
set_output_delay -clock clk_50mhz -min 0.0 [get_ports spi_ss]
