`timescale 1ns / 1ps

module testbench;

    // input signal
    logic clk;
    logic rst;

    // output signal
    logic Road1_G, Road1_Y, Road1_R;
    logic Road2_G, Road2_Y, Road2_R;
    logic Walk_G, Walk_R;

    // Instantiate the DUT
    TRAFFIC uut (
        .clk(clk), .rst(rst),
        .Road1_G(Road1_G), .Road1_Y(Road1_Y), .Road1_R(Road1_R),
        .Road2_G(Road2_G), .Road2_Y(Road2_Y), .Road2_R(Road2_R),
        .Walk_G(Walk_G), .Walk_R(Walk_R)
    );

    // Clock generation: 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Simulation process
    initial begin
        // initialize
        rst = 1;
        #20;
        rst = 0;

        // 執行 150 個 clock cycle
        #(150 * 10);  // 10ns * 150 = 1500ns

        // display ending
        $display("Simulation finished after 150 clock cycles.");
        $finish;
    end

    // print light
    always_ff @(posedge clk) begin
        $display("[%t] R1(GYR)=%0d%0d%0d  R2(GYR)=%0d%0d%0d  Walk(GR)=%0d%0d",
            $time,
            Road1_G, Road1_Y, Road1_R,
            Road2_G, Road2_Y, Road2_R,
            Walk_G, Walk_R
        );
    end

    // wave output
    initial begin
         $fsdbDumpfile("traffic.fsdb");
         $fsdbDumpvars(0, testbench);
        // $dumpfile("traffic.fsdb");
        // $dumpvars(0, testbench);    
    end

endmodule
