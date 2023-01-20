module sq_wave_gen (
    input clk,
    input next_sample,
    output [9:0] code
);

    localparam MAX = 278;
    localparam HALF = 139;

    reg [8:0] count = MAX - 1;
    reg level = 0;

    // Even though for the simulation this got the same result
    // I still believe we should be more clear on the use of clk

    always @(posedge next_sample) begin
        if (count == MAX - 1) count <= 0;
        else count <= count + 1;
        
        if (count == HALF - 1 || count == MAX - 1) level <= ~level;
        else level <= level;
    end

    // always @(posedge clk) begin
    //     if (next_sample) begin
    //         if (count == MAX - 1) count <= 0;
    //         else count <= count + 1;
            
    //         if (count == HALF - 1 || count == MAX - 1) level <= ~level;
    //         else level <= level;
    //     end else begin
    //         count <= count;
    //         level <= level;
    //     end
    // end

    assign code = level ? 562 : 462;
endmodule
