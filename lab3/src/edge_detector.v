module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);
    // TODO: implement a multi-bit edge detector that detects a rising edge of 'signal_in[x]'
    // and outputs a one-cycle pulse 'edge_detect_pulse[x]' at the next clock edge
    // Feel free to use as many number of registers you like
    reg [WIDTH-1:0] inversed_delay, temp;
    always @(posedge clk) begin
        inversed_delay <= ~signal_in;
        temp <= signal_in & inversed_delay;
    end

    // Remove this line once you create your edge detector
    assign edge_detect_pulse = temp;
endmodule
