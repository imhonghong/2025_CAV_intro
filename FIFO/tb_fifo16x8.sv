`timescale 1ns/1ps
module tb_fifo16x8;

  // DUT I/O
  logic         clk;
  logic         rstN;
  logic         write_en;
  logic         read_en;
  logic [15:0]  write_data;
  logic [15:0]  read_data;

  // Instantiate DUT
  TOP top (
    .clk        (clk),
    .rstN       (rstN),
    .write_en   (write_en),
    .read_en    (read_en),
    .write_data (write_data),
    .read_data  (read_data)
  );

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // ----------------------
  //  Stimulus helpers
  // ----------------------
  task automatic push(input logic [15:0] d);
    @(negedge clk);
    write_data = d;
    write_en   = 1'b1;
    read_en    = 1'b0;
    @(negedge clk);
    write_en   = 1'b0;
  endtask

  task automatic pop();
    @(negedge clk);
    read_en  = 1'b1;
    write_en = 1'b0;
    @(negedge clk);
    read_en  = 1'b0;
  endtask

  // 同拍讀+寫
  task automatic pushpop(input logic [15:0] d);
    @(negedge clk);
    write_data = d;
    write_en   = 1'b1;
    read_en    = 1'b1;
    @(negedge clk);
    write_en   = 1'b0;
    read_en    = 1'b0;
  endtask

  // ----------------------
  //  Test sequence
  // ----------------------
  initial begin
    // Init
    rstN       = 0;
    write_en   = 0;
    read_en    = 0;
    write_data = 0;

    // Reset：在 negedge 釋放，確保下個 posedge 前穩定
    repeat (2) @(posedge clk);
    @(negedge clk) rstN = 1;
    $display("[%0t] Release reset", $time);

    // === 1. Fill FIFO ===
    for (int i = 0; i < 8; i++) begin
      push(16'hA000 + i);
    end

    // === 2. Read all data ===
    for (int i = 0; i < 8; i++) begin
      pop();
    end

    // === 3. Fill again to full ===
    for (int i = 0; i < 8; i++) begin
      push(16'hB000 + i);
    end

    // === 4. Full + simultaneous read/write ===
    // 此時 FIFO 已滿（8 筆），做同拍 RW：計數不變、指標各前進。
    pushpop(16'hC123);

    // === 5. Drain to empty ===
    for (int i = 0; i < 8; i++) begin
      pop();
    end

    // === 6. Empty + simultaneous read/write (bypass) ===
    // 此時 FIFO 為空，做同拍 RW：read_data 當拍等於 write_data，指標/計數不變。
    pushpop(16'hD456);

    // End
    repeat (4) @(posedge clk);
    $finish;
  end

  // ----------------------
  //  FSDB dump for nWave
  // ----------------------
  initial begin
    $fsdbDumpfile("fifo16x8.fsdb");
    // 建議同時打開 +mda，或使用 fsdbDumpMDA 指定陣列
    //$fsdbDumpvars(0, tb_fifo16x8, "+mda");
    //$fsdbDumpMDA(tb_fifo16x8.dut.mem);
    $fsdbDumpvars();
    $fsdbDumpMDA;
  end

endmodule
