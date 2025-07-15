module uart_rx_rtl_1#(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD_RATE = 115200,
  parameter WIDTH = 8
)(
  input logic clk,
  input logic rst,
  input logic rx,
  output logic [WIDTH-1:0]rx_data,
  output logic rx_done
);
  localparam BAUD_PERIOD = CLK_FREQ / BAUD_RATE; // PERIOD: 434 = 50MHz (FPGA) / 115200 (baud rate
  localparam BAUD_PERIOD_HALF = BAUD_PERIOD/2;
  localparam LOG_WIDTH = $clog2(WIDTH);
  
  logic [LOG_WIDTH:0]bit_c;  		// 4bits for count 0~10
  logic [9:0]clk_c; 		 // 9bits for count 434
  logic rx_busy;    		 // check data receiving
  logic [WIDTH-1:0]reg_data;  		// for data register
  logic [WIDTH-1:0]rx_data_s;		  // for reg in sequential logic
  logic rx_pre;				// check falling edge start
  logic rx_check;				// check rx in idle state
  logic RX_FALLING_EDGE_CHECK;
  
  typedef enum logic[1:0]{
    IDLE,
    RX_START,
    RX_BUSY,
    RX_STOP
  }rx_state;
  
  rx_state current_state, next_state;
  
  assign rx_data = rx_data_s;
  assign RX_FALLING_EDGE_CHECK = (rx == 0 && rx_pre == 1);
  
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      current_state <= IDLE;
      rx_done <= 0;
      bit_c <= 0;
      clk_c <= 0;
      rx_busy <= 0;
      reg_data <= 0;
      rx_data_s <= 0;
      rx_pre <= 1;
      rx_check <= 1;
    end
    else begin
      current_state <= next_state;
      rx_done <= 0;		// for one pulse in rx_done
      rx_pre <= rx;		
      
      // set IDLE state
      if (current_state == IDLE) begin
        rx_busy <= 0;
        clk_c <= 0;
        bit_c <= 0;
        rx_check <= 1;
      end
      else begin
        rx_busy <= 1;
        rx_check <= 0;
      end
	  
      // set RX_START state
      if (current_state == RX_START) begin
        if (clk_c == BAUD_PERIOD_HALF-1) begin
            bit_c <= bit_c + 1;  // 0 -> 1
            clk_c <= 0;
        end
        else begin
            clk_c <= clk_c + 1;
        end
      end
	  
      // set RX_BUSY state
      if (current_state == RX_BUSY) begin
        if (clk_c == BAUD_PERIOD-1) begin
            bit_c <= bit_c + 1;  // 1~8, 9 will change to RX_STOP
            reg_data[bit_c - 1] <= rx;
            clk_c <= 0;
          if (bit_c == WIDTH) begin  // data received done & print out
              rx_data_s <= reg_data;
              rx_done <= 1;                
            end
        end
        else begin
            clk_c <= clk_c + 1;
        end
      end
	  
      // set RX_STOP state
      if (current_state == RX_STOP) begin
        if (clk_c == BAUD_PERIOD-1) begin
            rx_busy <= 0;
        end
        else begin
            clk_c <= clk_c + 1;
        end
      end
    
    end
  end
  
  always_comb begin
    next_state = current_state; // keep next state in same
    case (current_state)
      IDLE : begin
        if (!rx_busy && RX_FALLING_EDGE_CHECK && rx_check) begin
            next_state = RX_START;
        end
        else begin
            next_state = IDLE;  // can not start receive
        end
      end
      RX_START : begin
        if (clk_c == BAUD_PERIOD_HALF-1) begin
            if (rx == 0) begin
                next_state = RX_BUSY;
            end
            else begin
                next_state = IDLE;  // error: rx not in start bit 0, turn to IDLE
            end
        end
        else begin
            next_state = RX_START;  // wait for the count to reach the midpoint
        end
      end
      RX_BUSY : begin
        if (clk_c == BAUD_PERIOD-1) begin
          if (bit_c == WIDTH) begin
               next_state = RX_STOP; 
            end
            else begin
                next_state = RX_BUSY;
            end
        end
        else begin
          next_state = RX_BUSY; // wait for the count to reach the next point (midpoint)
        end
      end
      RX_STOP : begin
        if (clk_c == BAUD_PERIOD-1) begin
            if (rx == 1) begin
                next_state = IDLE;
            end
            else begin
                next_state = IDLE;  // error: rx not in stop bit 1, turn to IDLE
            end
        end
        else begin
            next_state = RX_STOP;
        end
      end
      default begin
        next_state = IDLE;
      end
    endcase
  end
  
endmodule