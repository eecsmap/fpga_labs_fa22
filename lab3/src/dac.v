module dac #(
    parameter CYCLES_PER_WINDOW = 1024,
    parameter CODE_WIDTH = $clog2(CYCLES_PER_WINDOW)
)(
    input clk,
    input [CODE_WIDTH-1:0] code,
    output next_sample,
    output pwm
);

    reg [CODE_WIDTH-1:0] count = 0;
    reg internal_next_sample = 0;
    reg internal_pwm = 0;

    always @(posedge clk) begin

        if (count == CYCLES_PER_WINDOW - 2) internal_next_sample <= 1;
        else internal_next_sample <= 0;

        if (count == CYCLES_PER_WINDOW - 1) count <= 0;
        else count <= count + 1;

        if (code == 0) internal_pwm <= 0;
        else if (count > code - 1 && count != CYCLES_PER_WINDOW - 1) internal_pwm <= 0;
        else internal_pwm <= 1;
    end

    assign pwm = internal_pwm;
    assign next_sample = internal_next_sample;

endmodule
