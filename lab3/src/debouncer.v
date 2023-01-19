
module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);
    // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
    // Some initial code has been provided to you, but feel free to change it however you like
    // One wrapping counter is required
    // One saturating counter is needed for each bit of glitchy_signal
    // You need to think of the conditions for reseting, clock enable, etc. those registers
    // Refer to the block diagram in the spec
    
    wire [WIDTH-1:0] sync_signal;

    synchronizer #(.WIDTH(WIDTH)) sync
    (.clk(clk), .async_signal(glitchy_signal), .sync_signal(sync_signal));

    wire pulse;
    sample_pulse_generator #(.MAX_COUNT(SAMPLE_CNT_MAX))
    spg (.clk(clk), .pulse(pulse));

    wire [WIDTH-1:0] reset;
    assign reset = ~sync_signal;

    wire [WIDTH-1:0] enable;
    wire [WIDTH-1:0] debounced;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign enable[i] = pulse & sync_signal[i];
            saturating_generator #(.MAX_COUNT(PULSE_CNT_MAX)) sat
            (.clk(clk), .reset(reset[i]), .enable(enable[i]), .out(debounced[i]));
        end
    endgenerate

    assign debounced_signal = debounced;
endmodule


// output a pulse for every MAX_COUNT clocks
module sample_pulse_generator
    #(parameter MAX_COUNT = 100)
    (input clk, output pulse);
    localparam WIDTH = $clog2(MAX_COUNT);

    reg out = 0;
    reg [WIDTH-1:0] count = 0;
    always @(posedge clk) begin
        if (count == MAX_COUNT - 1) begin
            count <= 0;
            out <= 1;
        end
        else begin
            count <= count + 1;
            out <= 0;
        end
    end
    assign pulse = out;
endmodule

// keep the output high as long as being saturated
module saturating_generator
    #(parameter MAX_COUNT = 100)
    (input clk, input enable, input reset, output out);
    localparam WIDTH = $clog2(MAX_COUNT) + 1;

    reg temp = 0;
    reg [WIDTH-1:0] count = 0;
    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            temp <= 0;
        end
        else begin
            if (enable && count < MAX_COUNT - 1) begin
                count <= count + 1;
                temp <= 0;
            end
            else if (count == MAX_COUNT || enable && count == MAX_COUNT - 1) begin
                count <= MAX_COUNT;
                temp <= 1;
            end
            else begin
                count <= count;
                temp <= 0;
            end
        end
    end
    assign out = temp;
endmodule
