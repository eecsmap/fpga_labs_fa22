module nco(
    input clk,
    input rst,
    input [23:0] fcw,
    input next_sample,
    output [9:0] code
);

    reg [9:0] sine_lut [0:255];
    initial begin
        $readmemb("sine.bin", sine_lut);
    end

    reg [23:0] i = 0;
    reg [9:0] internal_code = 0;
    always @(posedge clk) begin
        if (rst) begin
            i <= 0;
            internal_code <= sine_lut[0];
        end
        else if (next_sample) begin
            i <= i + fcw;
            internal_code <= sine_lut[(i + fcw) >> 16];
        end
        else begin
            i <= i;
            internal_code <= internal_code;
        end
    end

    assign code = internal_code;
endmodule
