`timescale 1ns/1ps

module uart_tx_tb_1 #(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD_RATE = 115200,
  parameter WIDTH = 8
)();
  logic clk;
  logic rst;
  logic [WIDTH-1:0]data;
  logic data_en;
  logic tx;
  logic busy;
  
  localparam BAUD_PERIOD = CLK_FREQ / BAUD_RATE;
  
  // module instance
  uart_tx_rtl_1 ins1(.tx(tx),
                     .tx_busy(busy),
                     .clk(clk),
                     .rst(rst),
                     .data(data),
                     .data_en(data_en)
                    );

  // task for input data
  task send_tx_data (input logic [WIDTH-1:0]send_data);
    @(posedge clk);
    wait (!busy);
    data = send_data;
    data_en = 1;
    @(posedge clk);
    data_en = 0;
    wait (busy);
    wait (!busy);
  endtask
  
  // tb
  initial begin
    $dumpfile("uart_tx_dumpfile.vcd");
    $dumpvars(0,ins1);
    $display("---Start Test TX---");
    
    clk = 0;
    rst = 0;
    data = 0;
    data_en = 0;
    
    @(posedge clk); 
    rst = 1;     // reset test
    repeat(2) @(posedge clk); 
    rst = 0;
    
    send_tx_data(8'd66);        // test a data1：8'd66 (01000010)
    repeat(10) @(posedge clk);
    send_tx_data(8'd111);		// test a data2：8'd111 (01000010)
    
//     #(434*10*10);
    
    $display("---End Test---");
    $finish;
  end
  
  // clock 
  always #(1s/(CLK_FREQ)*2) clk = ~clk;   // generate a clock with period 1/CLK_FREQ
  
  // display
  always @(posedge clk) begin
    if (ins1.clk_c == 433) begin
      $display("Time: %t | bit_c: %0d | tx: %b | reg_space: %b (%0d)",
             $time, ins1.bit_c, tx, ins1.reg_space, ins1.reg_space);
    end
  end
  
  //assert 
  always @(posedge clk) begin
    // tx keep output high when not busy
    if (!busy) begin
      assert (tx) else $error("TB Fail: TX not keep output high when not busy at time %t", $time);
    end
  end
  
  
endmodule