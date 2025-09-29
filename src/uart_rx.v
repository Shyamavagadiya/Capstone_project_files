module uart_rx #(parameter CLKS_PER_BIT = 434) (
    input  wire       i_clk,
    input  wire       i_rx_serial,
    output reg        o_rx_dv,
    output reg [7:0]  o_rx_byte
);

  localparam IDLE         = 3'b000;
  localparam START_BIT    = 3'b001;
  localparam DATA_BITS    = 3'b010;
  localparam STOP_BIT     = 3'b011;
  localparam CLEANUP      = 3'b100;

  reg [2:0]    r_SM_Main     = 0;
  reg [8:0]    r_Clock_Count = 0;
  reg [2:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Rx_Byte     = 0;

  always @(posedge i_clk) begin
    case (r_SM_Main)
      IDLE: begin
        o_rx_dv        <= 1'b0;
        r_Clock_Count  <= 0;
        r_Bit_Index    <= 0;

        if (i_rx_serial == 1'b0) // start bit detected
          r_SM_Main <= START_BIT;
        else
          r_SM_Main <= IDLE;
      end

      START_BIT: begin
        if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
          if (i_rx_serial == 1'b0) begin
            r_Clock_Count <= 0;
            r_SM_Main     <= DATA_BITS;
          end else
            r_SM_Main <= IDLE;
        end else begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= START_BIT;
        end
      end

      DATA_BITS: begin
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= DATA_BITS;
        end else begin
          r_Clock_Count          <= 0;
          r_Rx_Byte[r_Bit_Index] <= i_rx_serial;
          if (r_Bit_Index < 7) begin
            r_Bit_Index <= r_Bit_Index + 1;
            r_SM_Main   <= DATA_BITS;
          end else begin
            r_Bit_Index <= 0;
            r_SM_Main   <= STOP_BIT;
          end
        end
      end

      STOP_BIT: begin
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= STOP_BIT;
        end else begin
          o_rx_dv       <= 1'b1;
          o_rx_byte     <= r_Rx_Byte;
          r_Clock_Count <= 0;
          r_SM_Main     <= CLEANUP;
        end
      end

      CLEANUP: begin
        r_SM_Main <= IDLE;
        o_rx_dv   <= 1'b0;
      end

      default: r_SM_Main <= IDLE;
    endcase
  end
endmodule
