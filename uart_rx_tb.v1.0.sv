`timescale 1ns/1ps

module uart_tx_tb_1();
  reg clk;
  reg rst;
  reg rx;
  wire [7:0]rx_data;
  wire done;
  
  
  // module instance
  uart_rx_rtl_1 ins1 (.rx_data(rx_data),
                      .rx_done(done),
                      .clk(clk),
                      .rst(rst),
                      .rx(rx)
  );
  
  reg done_pre;		// for catch 1 done information
  
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

// //     test a data1：8'd66 (01000010) 
//     rx = 0; #(434 * 10);        // start bit
//     rx = 0; #(434 * 10);        // bit 0
//     rx = 1; #(434 * 10);        // bit 1
//     rx = 0; #(434 * 10);        // bit 2
//     rx = 0; #(434 * 10);        // bit 3
//     rx = 0; #(434 * 10);        // bit 4
//     rx = 0; #(434 * 10);        // bit 5  
//     rx = 1; #(434 * 10);        // bit 6   
//     rx = 0; #(434 * 10);        // bit 7
//     rx = 1; #(434 * 10);        // stop bit
   
//     #(434 * 10);
    
// //     test a data2：8'd111 (01101111) 
//     rx = 0; #(434 * 10);        // start bit 
//     rx = 1; #(434 * 10);        // bit 0  
//     rx = 1; #(434 * 10);        // bit 1
//     rx = 1; #(434 * 10);        // bit 2 
//     rx = 1; #(434 * 10);        // bit 3  
//     rx = 0; #(434 * 10);        // bit 4 
//     rx = 1; #(434 * 10);        // bit 5 
//     rx = 1; #(434 * 10);        // bit 6   
//     rx = 0; #(434 * 10);        // bit 7 
//     rx = 1; #(434 * 10);        // stop bit   
    
    
    // test a data1：8'd66 (01000010)  and reset in process
    rx = 0; #(434 * 10);        // start bit
    rx = 0; #(434 * 10);        // bit 0
    rx = 1; #(434 * 10);        // bit 1
    rx = 0; #(434 * 10);        // bit 2
    @(posedge clk);
    rst = 1;					//reset test
    repeat(2) @(posedge clk);
    rst = 0;
    repeat(10) @(posedge clk);
    rx = 1; 					// back to idle
    repeat(10) @(posedge clk); 
    rx = 0; #(434 * 10);        // start bit
    rx = 0; #(434 * 10);        // bit 0
    rx = 1; #(434 * 10);        // bit 1
    rx = 0; #(434 * 10);        // bit 2
    rx = 0; #(434 * 10);        // bit 3
    rx = 0; #(434 * 10);        // bit 4
    rx = 0; #(434 * 10);        // bit 5  
    rx = 1; #(434 * 10);        // bit 6   
    rx = 0; #(434 * 10);        // bit 7
    rx = 1; #(434 * 10);        // stop bit

      
    #(434 * 10);
    $display("---End Test---");
    $finish;
  end
  
  // clock
  always #5 clk = ~clk;
  
  // display informaion
  always @(posedge clk) begin
    if (ins1.clk_c == ins1.check_p && ins1.rx_busy) begin
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