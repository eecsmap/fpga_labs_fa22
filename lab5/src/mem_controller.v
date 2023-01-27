module mem_controller #(
  parameter FIFO_WIDTH = 8
) (
  input clk,
  input rst,                    // reset the state to idle
  input rx_fifo_empty,          // blocking reading din
  input tx_fifo_full,           // blocking writing dout
  input [FIFO_WIDTH-1:0] din,

  output rx_fifo_rd_en,         // signal to read din
  output tx_fifo_wr_en,         // signal to write dout
  output [FIFO_WIDTH-1:0] dout,
  output [5:0] state_leds
);

  localparam MEM_WIDTH = 8;   /* Width of each mem entry (word) */
  localparam MEM_DEPTH = 256; /* Number of entries */
  localparam NUM_BYTES_PER_WORD = MEM_WIDTH/8;
  localparam MEM_ADDR_WIDTH = $clog2(MEM_DEPTH); 

  reg [NUM_BYTES_PER_WORD-1:0] mem_we = 0;
  reg [MEM_ADDR_WIDTH-1:0] mem_addr;
  reg [MEM_WIDTH-1:0] mem_din;
  wire [MEM_WIDTH-1:0] mem_dout;

  reg [2:0] pkt_rd_cnt;
  reg [MEM_WIDTH-1:0] cmd;
  reg [MEM_WIDTH-1:0] addr;
  reg [MEM_WIDTH-1:0] data;
  reg handshake;
  
  memory #(
    .MEM_WIDTH(MEM_WIDTH),
    .DEPTH(MEM_DEPTH)
  ) mem(
    .clk(clk),
    .en(1'b1),
    .we(mem_we),
    .addr(addr),
    .din(mem_din),
    .dout(mem_dout)
  );

  localparam 
    IDLE = 3'd0,
    READ_CMD = 3'd1,
    READ_ADDR = 3'd2,
    READ_DATA = 3'd3,
    READ_MEM_VAL = 3'd4,
    ECHO_VAL = 3'd5,
    WRITE_MEM_VAL = 3'd6;

  reg [2:0] curr_state;
  reg [2:0] next_state;

  always @(posedge clk) begin

    /* state reg update */
    if (rst) curr_state <= IDLE;
    else curr_state <= next_state;

  end




  always @(*) begin
    
    /* initial values to avoid latch synthesis */
    next_state = curr_state;
    case (curr_state)
        /* next state logic */
        IDLE: begin
            if (!rx_fifo_empty) next_state = READ_CMD;
        end
        READ_CMD: begin
            if (!rx_fifo_empty) next_state = READ_ADDR;
        end
        READ_ADDR: begin
                if (cmd == 'd48) next_state = READ_MEM_VAL;
                else if(cmd == 'd49 && !rx_fifo_empty) next_state = READ_DATA;
        end
        READ_DATA: next_state = WRITE_MEM_VAL;
        READ_MEM_VAL: begin
            if (!tx_fifo_full) next_state = ECHO_VAL;
        end
        ECHO_VAL: begin
            next_state = IDLE;
        end
        WRITE_MEM_VAL: next_state = IDLE;
    endcase
  end


    always @(*) begin
        /* initial values to avoid latch synthesis */
        // case (curr_state)
        //     /* output and mem signal logic */
        //     IDLE:
        //     READ_CMD:
        //     READ_ADDR:
        //     READ_DATA:
        //     READ_MEM_VAL:
        //     ECHO_VAL:
        //     WRITE_MEM_VAL:
        // endcase
    end

    wire rd_en;
    assign rd_en = !rx_fifo_empty && (
        curr_state == IDLE
        || curr_state == READ_CMD
        || (curr_state == READ_ADDR && cmd == 'd49));

    wire wr_en;
    assign wr_en = !tx_fifo_full && (
        curr_state == ECHO_VAL);

    always @(posedge clk) begin

        /* byte reading and packet counting */

        if (curr_state == READ_CMD) cmd <= din;
        if (curr_state == READ_ADDR) addr <= din;
        if (curr_state == READ_DATA) data <= din;


        if (curr_state == READ_MEM_VAL) begin
            mem_addr <= addr;
        end

        if (curr_state == WRITE_MEM_VAL) begin
            mem_addr <= addr;
            mem_din <= data;
            mem_we[0] <= 1;
        end

        if (curr_state == IDLE) begin
            mem_we[0] <= 0;
        end
    end

  assign state_leds = curr_state;

  assign rx_fifo_rd_en = rd_en;
  assign tx_fifo_wr_en = wr_en;
  assign dout = mem_dout;

endmodule
