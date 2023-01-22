module sq_wave_gen #(
    parameter STEP = 10
)(
    input clk,
    input rst,
    input next_sample,
    input [2:0] buttons,
    output [9:0] code,
    output [3:0] leds
);

    // default to 440Hz, 125e6 / 1024 / 440 = 278
    // to support frequence in [20, 10000]
    // cycles to count should range
    // from ceil(125e6 / 1024 / 20) = 6104
    // to floor(125e6 / 1024 / 10000) = 12
    localparam SAMPLES_PER_PERIOD_MAX = 6104;    // < 20Hz
    localparam SAMPLES_PER_PERIOD_MIN = 12;      // > 10kHz
    localparam SAMPLES_PER_PERIOD_DEFAULT = 278; // 440Hz
    localparam COUNTER_WIDTH = $clog2(SAMPLES_PER_PERIOD_MAX);

    reg mode = 0;
    assign leds[0] = mode;

    reg [COUNTER_WIDTH-1:0] samples_per_period = SAMPLES_PER_PERIOD_DEFAULT;
    reg [COUNTER_WIDTH:0] temp_samples; // one more bit to allow temporarily beyond the boundaries
    always @(posedge clk) begin
        if (rst) begin
            samples_per_period <= SAMPLES_PER_PERIOD_DEFAULT;
            mode <= 0;
        end else begin
            // handle samples_per_period
            if (buttons[0] && mode == 0) temp_samples = samples_per_period - STEP;
            else if (buttons[0] && mode == 1) temp_samples = samples_per_period >> 1;
            else if (buttons[1] && mode == 0) temp_samples = samples_per_period + STEP;
            else if (buttons[1] && mode == 1) temp_samples = samples_per_period << 1;
            else temp_samples = samples_per_period;
            if (temp_samples > SAMPLES_PER_PERIOD_MAX) temp_samples = SAMPLES_PER_PERIOD_MAX;
            if (temp_samples < SAMPLES_PER_PERIOD_MIN) temp_samples = SAMPLES_PER_PERIOD_MIN;
            samples_per_period <= temp_samples;

            // handle mode
            if (buttons[2]) mode <= ~mode;
            else mode <= mode;
        end
    end

    // output level
    reg level = 0;
    reg [COUNTER_WIDTH-1:0] count = SAMPLES_PER_PERIOD_DEFAULT - 1;
    always @(posedge next_sample) begin
        if (count == (samples_per_period >> 1) - 1 || count == samples_per_period - 1) level <= ~level;
        else level <= level;

        // handle count
        if (count == samples_per_period - 1) count <= 0;
        else count <= count + 1;
    end

    assign leds[3] = level;
    assign code = level ? 562 : 462;
endmodule
