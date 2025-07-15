`timescale 1ns/1ps

module uart_rx_tb_1 #(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD_RATE = 115200,
  parameter WIDTH = 8
)();
  logic clk;
  logic rst;
  logic rx;
  logic [WIDTH-1:0]rx_data;
  logic done;
  
  logic done_pre;		// for catch 1 done information
  
  localparam BAUD_PERIOD = CLK_FREQ / BAUD_RATE;
  
  
  // module instance
  uart_rx_rtl_1 ins1 (.rx_data(rx_data),
                      .rx_done(done),
                      .clk(clk),
                      .rst(rst),
                      .rx(rx)
  );
  
  // task
  task send_rx_data(input logic[WIDTH-1:0] send_rx);
    integer i;
    
    begin
      // start bit 0
      rx = 0;
      #(BAUD_PERIOD*(1s/(CLK_FREQ)));
      // data 0~7
      for (i=0;i<WIDTH;i=i+1) begin
        rx = send_rx[i];
        #(BAUD_PERIOD*(1s/(CLK_FREQ)));
      end
      // stop bit 1
      rx = 1;
      #(BAUD_PERIOD*(1s/(CLK_FREQ)));
    
    end
  endtask
  
  // tb
  initial begin
    $dumpfile("dumpfile_rx.vcd");
    $dumpvars(0, ins1);
    $display("---Start Test RX---");
    
    clk = 0;
    rst = 0;
    rx = 1;
    done_pre = 0;
    
    @(posedge clk);
    rst = 1;					//reset test
    repeat(2) @(posedge clk);
    rst = 0;
    
    repeat(10) @(posedge clk);
    #(BAUD_PERIOD*(1s/(CLK_FREQ)));
	
//     test a data1：8'd66 (01000010) 
    send_rx_data(8'd66);
    #(BAUD_PERIOD*(1s/(CLK_FREQ)));
    
//     test a data2：8'd111 (01101111) 
    send_rx_data(8'd111);   
    #(BAUD_PERIOD*(1s/(CLK_FREQ)));
    
    $display("---End Test---");
    $finish;
  end
  
  // clock
  always #(1s/(CLK_FREQ*2)) clk = ~clk;   // generate a clock with period 1/CLK_FREQ
  
  // display informaion
  always @(posedge clk) begin
    if (ins1.clk_c == (BAUD_PERIOD - 1) && ins1.rx_busy) begin
      $display("Time: %t | bit_c: %0d | rx: %b | reg_data: %b (%0d)",
               $time, ins1.bit_c, rx, ins1.reg_data, ins1.reg_data);
    end
    if (ins1.rx_done && !done_pre) begin
      $display("Received the data at %t ns| RX DONE: rx_data = %b (dec = %0d)", $time, rx_data, rx_data);
      done_pre <= ins1.rx_done;
    end
    else begin
      done_pre <= ins1.rx_done;
    end
  end
  
  
endmodule