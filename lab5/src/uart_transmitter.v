module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);
    // See diagram in the lab guide
    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;

    //--|Counters|----------------------------------------------------------------

    // Counts cycles until a single symbol is done
    always @ (posedge clk) begin
        clock_counter <= (start || reset || symbol_edge) ? 0 : clock_counter + 1;
    end

    // raise at the end of a symbol?
    wire symbol_edge;
    assign symbol_edge = clock_counter == (SYMBOL_EDGE_TIME - 1);

    reg [3:0] bit_counter;

    wire tx_running;
    assign tx_running = bit_counter != 4'd0;

    // Goes high when it is time to start sending a new character
    wire start;
    assign start = data_in_valid && !tx_running;

    always @(posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
        end else if (start) begin
            
            bit_counter <= 10;
        end else if (symbol_edge && tx_running) begin
            bit_counter <= bit_counter - 1;
        end
    end

    // shift sending bit
    reg [9:0] tx_shift;
    always @(posedge clk) begin
        if (start) tx_shift <= {1'b1, data_in, 1'b0};
        else if (symbol_edge && tx_running) tx_shift <= tx_shift >> 1;
    end
    assign serial_out = tx_running ? tx_shift[0] : 1'b1;

    // signal data_in_ready when finish sending.
    reg finish;
    always @(posedge clk) begin
        if (reset) finish <= 1;
        else if (bit_counter == 1 && symbol_edge) finish <= 1;
        else if (data_in_valid) finish <= 0;
    end

    assign data_in_ready = finish && !tx_running;
endmodule
