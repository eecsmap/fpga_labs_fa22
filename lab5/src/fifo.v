module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);

    reg [POINTER_WIDTH:0] count;
    reg [POINTER_WIDTH-1:0] read_ptr, write_ptr;
    reg [WIDTH-1:0] data [0:DEPTH-1];

    reg [WIDTH-1:0] reg_out;
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            read_ptr <= 0;
            write_ptr <= 0;
        end else begin
            if (wr_en && rd_en) begin
                if (count == 0) reg_out <= din;
                else begin
                    data[write_ptr] <= din;
                    write_ptr <= write_ptr + 1;
                    read_ptr <= read_ptr + 1;
                    reg_out <= data[read_ptr];
                end
            end else begin
                if (wr_en && !full) begin
                    data[write_ptr] <= din;
                    write_ptr <= write_ptr + 1;
                    count <= count + 1;
                end
                if (rd_en && !empty) begin
                    read_ptr <= read_ptr + 1;
                    reg_out <= data[read_ptr];
                    count <= count - 1;
                end
            end
        end
    end

    assign full = count == DEPTH;
    assign empty = count == 0;
    assign dout = reg_out;
endmodule
