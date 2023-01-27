module fixed_length_piano #(
    parameter CYCLES_PER_SECOND = 125_000_000
) (
    input clk,
    input rst,

    input [2:0] buttons,
    output [5:0] leds,

    output [7:0] ua_tx_din,
    output ua_tx_wr_en,
    input ua_tx_full,

    input [7:0] ua_rx_dout,
    input ua_rx_empty,
    output ua_rx_rd_en,

    output [23:0] fcw
);

    localparam 
        IDLE = 3'd0,
        READ = 3'd1,
        ECHO = 3'd2;

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
                if (!ua_rx_empty) next_state = READ;
            end
            READ: begin
                if (!ua_tx_full) next_state = ECHO;
            end
            ECHO: begin
                next_state = IDLE;
            end
        endcase
    end

    wire rd_en;
    assign rd_en = !ua_rx_empty && curr_state == IDLE;

    wire wr_en;
    assign wr_en = !ua_tx_full && curr_state == ECHO;

    reg [7:0] data;
    reg new_key;
    always @(posedge clk) begin
        new_key <= 0;
        if (curr_state == READ) begin
            data <= ua_rx_dout;
            new_key <= 1;
        end
    end

    wire [7:0] rom_address;
    wire [23:0] rom_data;
    wire [7:0] rom_last_address;
    piano_scale_rom rom(.address(data), .data(rom_data), .last_address(rom_last_address));

    reg [28:0] limit = 25000000;
    reg [28:0] count;

    localparam STEP = 1250000;
    always @(posedge clk) begin
        if (rst) count <= 0;
        else if (new_key) count <= limit - 1;
        else if (count) count <= count - 1;
        else count <= 0;

        if (rst) limit = 25000000;
        else if (buttons[0]) limit <= limit + STEP;
        else if (buttons[1]) limit <= limit - STEP;
    end

    assign fcw = count ? rom_data : 0;
    assign ua_tx_din = data;
    assign ua_tx_wr_en = wr_en;
    assign ua_rx_rd_en = rd_en;
    assign leds = curr_state;
endmodule
