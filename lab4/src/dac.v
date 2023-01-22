module dac #(
    parameter CYCLES_PER_WINDOW = 1024,
    parameter CODE_WIDTH = $clog2(CYCLES_PER_WINDOW)
)(
    input clk,
    input rst,
    input [CODE_WIDTH-1:0] code,
    output next_sample,
    output reg pwm
);

    reg [CODE_WIDTH-1:0] count;
    reg internal_next_sample;

    always @(posedge clk) begin
        // count
        if (rst || count == CYCLES_PER_WINDOW - 1) count <= 0;
        else count <= count + 1;

        // pwm
        // we want to output pwm = 1 in slice [0, 1, ..., code]
        // however, when code is 0, output pwm = 0 all the time.
        if (code != 0 && (count <= code - 1 || count == CYCLES_PER_WINDOW - 1)) pwm <= 1;
        else pwm <= 0;

        // signal next_sample at slice[CYCLES_PER_WINDOW - 1]
        if (count == CYCLES_PER_WINDOW - 2) internal_next_sample <= 1;
        else internal_next_sample <= 0;
    end

    assign next_sample = internal_next_sample;
endmodule
