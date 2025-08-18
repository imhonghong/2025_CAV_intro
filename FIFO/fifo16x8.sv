`timescale 1ns/1ps
module TOP #(
    localparam int WIDTH = 16,
    localparam int DEPTH = 8,
    localparam int AW    = $clog2(DEPTH)
) (
    input  logic                clk,
    input  logic                rstN,         // active low
    input  logic                write_en,     // write request
    input  logic                read_en,      // read request
    input  logic [WIDTH-1:0]    write_data,
    output logic [WIDTH-1:0]    read_data,
    output logic                empty,
    output logic                full
);

    // storage
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // state
    logic [AW-1:0]  wr_ptr, rd_ptr, wr_ptr_n, rd_ptr_n;
    logic [AW:0]    count, count_n;
    // logic           empty, full;
    logic           do_write, do_read;

    // next-state for read_data
    logic [WIDTH-1:0] read_data_n;

    // 用來告知 seq 區塊是否真的要寫 mem
    logic wr_do;

    // status logic
    assign empty    = (count == 0);
    assign full     = (count == DEPTH);
    assign do_write = write_en && (!full  || read_en);
    assign do_read  = read_en  && (!empty || write_en);

    // next state logic（先讀後寫）
    always_comb begin
        // default
        wr_ptr_n    = wr_ptr;
        rd_ptr_n    = rd_ptr;
        count_n     = count;
        read_data_n = read_data;
        wr_do       = 1'b0;    // 預設不寫入記憶體

        // 讀
        if (do_read) begin
            if (empty && write_en) begin
                // bypass：空+同拍RW → 當拍輸出 write_data，不動指標/計數
                read_data_n = write_data;
            end else begin
                read_data_n = mem[rd_ptr];
                rd_ptr_n    = (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1;
                count_n     = count_n - 1;   // 注意用 count_n 累加/累減
            end
        end

        // 寫（滿+同拍RW允許；空+同拍RW已在上面bypass，因此此處要略過）
        if (do_write) begin
            if (!(empty && read_en)) begin
                wr_do    = 1'b1;                                   // 交給 seq 區塊寫 mem
                wr_ptr_n = (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1;  // 下一拍指標前進
                count_n  = count_n + 1;                             // 用 count_n
            end
        end
    end

    // sequential（同步寫入 mem，同步更新指標/計數/輸出）
    always_ff @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            wr_ptr     <= '0;
            rd_ptr     <= '0;
            count      <= '0;
            read_data  <= '0;
        end else begin
            if (wr_do) begin
                // 標準 FIFO 寫法：用「當拍的 wr_ptr」地址寫入
                mem[wr_ptr] <= write_data;
                // 如果你希望波形上「寫入位置」和 wr_ptr 更新更直觀，也可改成：
                // mem[wr_ptr_n] <= write_data;
            end

            wr_ptr     <= wr_ptr_n;
            rd_ptr     <= rd_ptr_n;
            count      <= count_n;
            read_data  <= read_data_n;
        end
    end

endmodule
