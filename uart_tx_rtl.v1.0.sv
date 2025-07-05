module uart_tx_rtl_1(
  input clk,
  input rst,
  input [7:0]data,
  input data_en,
  output trans,
  output reg trans_busy
);

  reg [9:0]reg_space;   // start(1'b0) + data(8bits) + stop(1'b1) , total = 10 bits
  reg [3:0]bit_c;   // 4 bits count for 0~15
  reg [9:0]clk_c;  // 9 bits count for 434, range 0~511
  reg trans_s; // for reg in sequential logic

  // clk: 434 = 50MHz (FPGA) / 115200 (baud rate)
  
  assign trans = trans_s;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      trans_busy <= 0;
      reg_space <= 10'd1023;  // for protocal idle in high level
      bit_c <= 0;
      clk_c <= 0;
      trans_s <= 1;           // for protocal idle in high level
    end
    else begin
      if (data_en && !trans_busy) begin
        trans_busy <= 1;
        reg_space <= {1'b1,data,1'b0};   // stop + data[7:0] + start
        bit_c <= 0;
        clk_c <= 0;
      end
      else if (trans_busy) begin
        if (clk_c == 433) begin          // check on clk (434-1) 
          clk_c <= 0;
          trans_s <= reg_space[0];
          reg_space <= reg_space >> 1;   // right shift 0 -> data[0]~data[7] -> 1 
          bit_c <= bit_c + 1;
          if (bit_c == 9) begin
            trans_busy <= 0;  // data[0]:bit_c(1), data[7]:bits_c(8)
          end
        end
        else begin
          clk_c <= clk_c + 1;
        end
      end
    end
  end
  
endmodule