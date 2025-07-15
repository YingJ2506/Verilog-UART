module uart_tx_rtl_1 #(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD_RATE = 115200,
  parameter WIDTH = 8
)(
  input logic clk,
  input logic rst,
  input logic[WIDTH-1:0]data,
  input logic data_en,
  output logic tx,
  output logic tx_busy
);
  
  localparam BAUD_PERIOD = CLK_FREQ / BAUD_RATE; // PERIOD: 434 = 50MHz (FPGA) / 115200 (baud rate)
  localparam LOG_WIDTH = $clog2(WIDTH);
  localparam REG_SPACE_WIDTH = WIDTH + 2;
  localparam OUTPUT_HIGH = (1'b1 << REG_SPACE_WIDTH) - 1;  // as 1024 - 1
  
  logic [WIDTH+1:0]reg_space;   // start(1'b0) + data(8bits) + stop(1'b1) , total = 10 bits
  logic [LOG_WIDTH:0]bit_c;   // 4 bits count for 0~9 (max: 15)
  logic [9:0]clk_c;  // 9 bits count for 434, range 0~511
  logic tx_s; // for reg in sequential logic

  
  assign tx = tx_s;
  
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      tx_busy <= 0;
      reg_space <= OUTPUT_HIGH;  // initialize to max value to keep TX output high during idle/reset
      bit_c <= 0;
      clk_c <= 0;
      tx_s <= 1;           // initialize to max value to keep TX output high during idle/reset
    end
    else begin
      if (data_en && !tx_busy) begin
        tx_busy <= 1;
        reg_space <= {1'b1,data[WIDTH-1:0],1'b0};   // stop + data[7:0] + start
        bit_c <= 0;
        clk_c <= 0;
      end
      else if (tx_busy) begin
        if (clk_c == BAUD_PERIOD - 1) begin          // check on clk (434-1) 
          if (bit_c == WIDTH + 1) begin   			// stop in bit_c == 9 , 1'b1
            tx_busy <= 0;  
            tx_s <= 1;  		     // max value to keep TX output high during idle/reset
            reg_space <= OUTPUT_HIGH;
          end 
          else begin
            clk_c <= 0;
            tx_s <= reg_space[0];
            reg_space <= reg_space >> 1;   // right shift 0 -> data[0]~data[7] -> 1 
            bit_c <= bit_c + 1;
          end
        end
        else begin
          clk_c <= clk_c + 1;
        end
      end
    end
  end
  
  // assert block
  always @(posedge clk)begin
    // check for max value to keep TX output high during idle/reset
    if (!tx_busy && !tx_s) begin
      $error("RTL Fail: TX is low when not busy at time %t", $time);
    end
    // check for bit_c not over WIDTH + 1
    if (bit_c > WIDTH + 1) begin
      $error("RTL Fail: TX over counting at time %t", $time);
    end
  end
  
endmodule