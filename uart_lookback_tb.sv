`timescale 1ns/1ps

module uart_lookback_tb();
  logic clk;
  logic rst;
  
  logic [7:0]data;
  logic data_en;
  logic trans;
  logic busy;  

  logic rx;
  logic [7:0]rx_data;
  logic done;
  
  
  // module instance
  uart_tx_rtl_1 ins_tx1 (.trans(trans),
                         .trans_busy(busy),
                         .clk(clk),
                         .rst(rst),
                         .data(data),
                         .data_en(data_en)
  );
  uart_rx_rtl_1 ins_rx1 (.rx_data(rx_data),
                         .rx_done(done),
                         .clk(clk),
                         .rst(rst),
                         .rx(trans)   // connect
  );
  
  
  // tb
  initial begin
    $dumpfile("dumpfile_uart.vcd");
    $dumpvars(0, uart_lookback_tb);
    $display("---Start Test RX---");
    
    clk = 0;
    rst = 0;
    data = 0;
    data_en = 0;
    
    #5 rst = 1;     // reset test
    #15 rst = 0;
    
    #20;
    data <= 8'd66;  // data1 input 8'd66 (01000010)
    data_en <= 1;
    #20;
    data_en <= 0;
    

   
    #(434 * 10*10);
    
    #20;
    data <= 8'd111;  // data2 input 8'd111 (01101111) 
    data_en <= 1;
    #20;
    data_en <= 0;    
    
    #(434 * 10*10);
    
      
    #(434 * 10);
    $display("---End Test---");
    $finish;
  end
  
  // clock
  always #5 clk = ~clk;
  
  
  
endmodule