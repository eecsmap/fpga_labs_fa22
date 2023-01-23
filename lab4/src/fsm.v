module fsm #(
    parameter CYCLES_PER_SECOND = 125_000_000,
    parameter WIDTH = $clog2(CYCLES_PER_SECOND)
)(
    input clk,
    input rst,
    input [2:0] buttons,
    output [3:0] leds,
    output [23:0] fcw,
    output [1:0] leds_state
);

    // ============================================================
    // states declaration
    // ============================================================
    localparam STATE_REGULAR_PLAY = 0;
    localparam STATE_REVERSE_PLAY = 1;
    localparam STATE_PAUSED = 2;
    localparam STATE_EDIT = 3;

    
    // ============================================================
    // computation of next state
    // ============================================================
    reg [1:0] current_state = STATE_REGULAR_PLAY;
    reg [1:0] next_state;
    assign leds_state = current_state;
    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_REGULAR_PLAY: 
                if (buttons[1]) next_state = STATE_REVERSE_PLAY;
                else if (buttons[0]) next_state = STATE_PAUSED;
            STATE_REVERSE_PLAY:
                if (buttons[1]) next_state = STATE_REGULAR_PLAY;
                else if (buttons[0]) next_state = STATE_PAUSED;
            STATE_PAUSED:
                if (buttons[0]) next_state = STATE_REGULAR_PLAY;
                else if (buttons[2]) next_state = STATE_EDIT;
            STATE_EDIT:
                if (buttons[2]) next_state = STATE_PAUSED;
        endcase
    end
    
    // ============================================================
    // switch state on clock
    // ============================================================
    always @(posedge clk) begin
        if (rst) current_state <= STATE_REGULAR_PLAY;
        else current_state <= next_state;
    end

    // count to a second and make a signal when count == 0
    // only count when playing or reversely playing the note
    reg [WIDTH-1:0] count = 0;
    reg one_second = 0;
    always @(posedge clk) begin
        if (rst) count <= 0;
        else if (current_state == STATE_REGULAR_PLAY || current_state == STATE_REVERSE_PLAY) begin
            if (count == CYCLES_PER_SECOND - 1) count <= 0;
            else count <= count + 1;
        end

        // signal one second
        if (!rst && (current_state == STATE_REGULAR_PLAY || current_state == STATE_REVERSE_PLAY) && count == CYCLES_PER_SECOND - 2) one_second <= 1;
        else one_second <= 0;
    end

    // ============================================================
    // choose next note to play
    // ============================================================
    reg [1:0] note_addr = 0;
    always @(posedge clk) begin
        if (rst) note_addr <= 0;
        //option 1: set the one_second on the count == CYCLES_PER_SECOND / 1000 - 2
        else if (one_second) begin
            case (current_state)
                STATE_REGULAR_PLAY: note_addr <= note_addr + 1;
                STATE_REVERSE_PLAY: note_addr <= note_addr - 1;
                default: note_addr <= note_addr;
            endcase
        end
    end

    // option 2: set the one_second on the count == CYCLES_PER_SECOND / 1000 - 1
    // this can get the same simulation result yet does not function correct on board
    // always @(posedge one_second) begin
    //     if (!rst)
    //         case (current_state)
    //             STATE_REGULAR_PLAY: note_addr <= note_addr + 1;
    //             STATE_REVERSE_PLAY: note_addr <= note_addr - 1;
    //             default: note_addr <= note_addr;
    //         endcase
    // end

    // ============================================================
    // indicating current node using leds
    // ============================================================
    reg [3:0] _leds;
    always @(posedge clk) begin
        _leds = 4'b0000;
        case (note_addr)
            'd0: _leds[0] = 1;
            'd1: _leds[1] = 1;
            'd2: _leds[2] = 1;
            'd3: _leds[3] = 1;
        endcase
    end
    assign leds = _leds;


    // ============================================================
    // pick up fcw to output
    // ============================================================
    reg [23:0] _fcw = 0;
    always @(*) begin
        case (current_state)
            STATE_REGULAR_PLAY: _fcw = d_out;
            STATE_REVERSE_PLAY: _fcw = d_out;
            STATE_EDIT: _fcw = _fcw_edit;
            default: _fcw = 0;
        endcase
    end
    assign fcw = _fcw;

    localparam FCW_MAX = 1375182; // 10kHz
    localparam FCW_MIN = 2750; // 20Hz
    localparam STEP = 10000;
    // ============================================================
    // edit
    // ============================================================
    reg [23:0] _fcw_edit = 0;
    reg _wr_en = 0;
    reg [23:0] _temp = 0;
    always @(posedge clk) begin
        if (current_state == STATE_EDIT) begin
            if (buttons[0]) begin
                _temp = _fcw_edit - STEP;
                if (_temp > _fcw_edit) _temp = FCW_MIN; // underflow
            end
            else if (buttons[1]) begin
                _temp = _fcw_edit + STEP;
                if (_temp < _fcw_edit) _temp = FCW_MAX; // overflow
            end
            else _temp = _fcw_edit;
            if (_temp < FCW_MIN) _temp = FCW_MIN;
            if (_temp > FCW_MAX) _temp = FCW_MAX;
            _fcw_edit <= _temp;

            if (rst) _wr_en <= 0;
            else _wr_en = 1;
        end
        else begin
            _fcw_edit <= d_out;
            _wr_en = 0;
        end
    end

    assign d_in = _fcw_edit;

    wire [1:0] addr;
    assign addr = note_addr;    

    wire wr_en, rd_en;
    assign rd_en = 1;
    assign wr_en = _wr_en;

    wire [23:0] d_in, d_out;

    fcw_ram notes (
        .clk(clk),
        .rst(rst),
        .rd_en(rd_en),
        .wr_en(wr_en),
        .addr(addr),
        .d_in(d_in),
        .d_out(d_out)
    );
endmodule
