module uart_tx #(parameter CLKS_PER_BIT = 434) (
    input  wire       i_clk,
    input  wire       i_tx_dv,
    input  wire [7:0] i_tx_byte,
    output reg        o_tx_active,
    output reg        o_tx_serial,
    output reg        o_tx_done
);

  localparam IDLE         = 3'b000;
  localparam START_BIT    = 3'b001;
  localparam DATA_BITS    = 3'b010;
  localparam STOP_BIT     = 3'b011;
  localparam CLEANUP      = 3'b100;

  reg [2:0]    r_SM_Main     = 0;
  reg [8:0]    r_Clock_Count = 0;
  reg [2:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Tx_Data     = 0;

  always @(posedge i_clk) begin
    case (r_SM_Main)
      IDLE: begin
        o_tx_serial   <= 1'b1;
        o_tx_done     <= 1'b0;
        r_Clock_Count <= 0;
        r_Bit_Index   <= 0;
        if (i_tx_dv == 1'b1) begin
          o_tx_active <= 1'b1;
          r_Tx_Data   <= i_tx_byte;
          r_SM_Main   <= START_BIT;
        end else begin
          r_SM_Main <= IDLE;
        end
      end

      START_BIT: begin
        o_tx_serial <= 1'b0;
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= START_BIT;
        end else begin
          r_Clock_Count <= 0;
          r_SM_Main     <= DATA_BITS;
        end
      end

      DATA_BITS: begin
        o_tx_serial <= r_Tx_Data[r_Bit_Index];
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= DATA_BITS;
        end else begin
          r_Clock_Count <= 0;
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
        o_tx_serial <= 1'b1;
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= STOP_BIT;
        end else begin
          o_tx_done     <= 1'b1;
          r_Clock_Count <= 0;
          r_SM_Main     <= CLEANUP;
          o_tx_active   <= 1'b0;
        end
      end

      CLEANUP: begin
        r_SM_Main <= IDLE;
        o_tx_done <= 1'b0;
      end

      default: r_SM_Main <= IDLE;
    endcase
  end
endmodule
