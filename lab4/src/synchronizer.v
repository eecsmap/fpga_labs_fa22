module synchronizer #(parameter WIDTH = 1) (
    input [WIDTH-1:0] async_signal,
    input clk,
    output [WIDTH-1:0] sync_signal
);
    // TODO: Create your 2 flip-flop synchronizer here
    // This module takes in a vector of WIDTH-bit asynchronous
    // (from different clock domain or not clocked, such as button press) signals
    // and should output a vector of WIDTH-bit synchronous signals
    // that are synchronized to the input clk
    reg [WIDTH-1:0] temp1 = 0;
    reg [WIDTH-1:0] temp2 = 0;
    always @(posedge clk) begin
        temp1 <= async_signal;
        temp2 <= temp1;
    end

    assign sync_signal = temp2;
endmodule
