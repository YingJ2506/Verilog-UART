module uart_rx_rtl_1(
  input clk,
  input rst,
  input rx,
  output [7:0]rx_data,
  output reg rx_done
);
  reg [3:0]bit_c;  		// 4bits for count 0~10
  reg [15:0]clk_c; 		 // 9bits for count 434
  reg rx_busy;    		 // check data receiving
  reg [15:0]check_p;  		// for check data in 434>>1
  reg [7:0]reg_data;  		// for data register
  reg [7:0]rx_data_s;		  // for reg in sequential logic
  reg rx_pre;				// check falling edge start
  reg rx_check;				// check

  // clk: 434 = 50MHz (FPGA) / 115200 (baud rate)
  
  assign rx_data = rx_data_s;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      rx_done <= 0;
      bit_c <= 0;
      clk_c <= 0;
      rx_busy <= 0;
      reg_data <= 0;
      rx_data_s <= 0;
      rx_pre <= 1;
      rx_check <= 0;
    end
    else begin
      rx_done <= 0;  // idle : 0
      rx_pre <= rx;
      if (rx == 1)			// rx return to high level (idle) , turn on rx_check to next data receive
        rx_check <= 1;
      if (!rx_busy && !rx && rx_pre && rx_check) begin  	// data in when rx from 1 to 0 (protocol)
        rx_busy <= 1;
        bit_c <= 0;
        clk_c <= 0;
        check_p <= 434 >> 1;		// as 434/2 = 217
        reg_data <= 0;
        rx_check <= 0;
      end
      else if (rx_busy) begin
        if (clk_c == check_p) begin
          // check for start bit
          if (bit_c == 0) begin		// check start bit is right sign
            if (rx == 0) begin
              check_p <= check_p + 434;  	// next check point
              bit_c <= bit_c + 1;                  
            end
            else begin
              rx_busy <= 0;			// remove wrong sign
            end
          end
          // do the data receving		
          else if (bit_c >= 1 && bit_c <= 8) begin 		// bit_c 1~8 : data[0~7]
            reg_data[bit_c - 1] <= rx;
            bit_c <= bit_c + 1;   
            check_p <= check_p + 434;
          end
          else if (bit_c == 9) begin						// bit_c 9 : stop
            rx_data_s <= reg_data;
            rx_done <= 1;
            rx_busy <= 0;
          end
       // pulse 1 clock on rx_done
       if (rx_done) begin		
         rx_done <= 0;
       end
        end
      else begin
        clk_c <= clk_c + 1;
      end
      end
    end
  end
  
endmodule