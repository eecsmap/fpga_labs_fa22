`timescale 1ns/1ns
`define CLK_PERIOD 8

module fsm_tb();
    // Generate 125 Mhz clock
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    // I/O
    reg rst;
    reg [2:0] buttons;
    wire [23:0] fcw;
    wire [3:0] leds;
    wire [1:0] leds_state;

    fsm #(.CYCLES_PER_SECOND(125_000_000)) DUT (
        .clk(clk),
        .rst(rst),
        .buttons(buttons),
        .leds(leds),
        .leds_state(leds_state),
        .fcw(fcw)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("fsm_tb.fst");
            $dumpvars(0, fsm_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        rst = 1;
        @(posedge clk); #1;
        rst = 0;

        buttons = 0;

        // TODO: toggle the buttons
        // verify state transitions with the LEDs
        // verify fcw is being set properly by the FSM
        @(posedge clk); #1;
        // @(posedge clk); #1;
        assert(leds_state == 0) else $error("init state should be 0 for regular play");
        assert(DUT.note_addr == 0) else $error("init node addr should be 0");
        assert(leds == 1) else $error("initially leds[0] should be on but get %b", leds);
        assert(DUT.addr == 0) else $error("init mem addr should be 0");
        assert(DUT.rd_en == 1) else $error("rd_en should be set");
        assert(DUT.wr_en == 0) else $error("wr_en should be cleaned");
        assert(DUT.d_out == 'd60508) else $error("d_out should be 'd60508 but get %d", DUT.d_out);
        // assert(DUT._from_d_out == 'd60508) else $error("_from_d_out should be 'd60508 but get %d", DUT._from_d_out);
        assert(fcw == 'd60508) else $error("fcw should be d60508 but get %d", fcw);

        // to run the test, set count == CYCLES_PER_SECOND / 1000 - 1 as the one_second signal
        // repeat (124999) @(posedge clk);
        // #1;
        // assert(leds == 'b0001) else $error("last cycle in first note, leds = %b", leds);
        // assert(fcw == 'd60508) else $error("fcw should be d60508 but get %d", fcw);

        // @(posedge clk); #1;
        // assert(leds == 'b0010) else $error("first cycle in second note, leds = %b", leds);
        // assert(fcw == 'd67934) else $error("fcw should be d67934 but get %d", fcw);

        buttons[0] = 1;
        @(posedge clk); #1;
        buttons[0] = 0;
        @(posedge clk); #1;
        assert(leds_state == 2) else $error("pause mode, actual %b", leds_state);
        buttons[2] = 1;
        assert(fcw == 0) else $error("fcw should be 0 but get %d", fcw);
        @(posedge clk); #1;
        buttons[2] = 0;
        @(posedge clk); #1;
        assert(leds_state == 3) else $error("edit mode, actual %b", leds_state);
        buttons[0] = 1;
        @(posedge clk); #1;
        buttons[0] = 0;
        @(posedge clk); #1;
        assert(fcw == 'd60508 - 'd10000) else $error("fcw should be %d but get %d", 'd60508 - 'd10000, fcw);
        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule
