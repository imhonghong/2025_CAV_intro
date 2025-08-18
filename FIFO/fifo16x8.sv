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
    output logic [WIDTH-1:0]    read_data,    // FWFT：組合輸出
    output logic                empty,
    output logic                full
);

    // storage
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // state
    logic [AW-1:0]  wr_ptr, rd_ptr, wr_ptr_n, rd_ptr_n;
    logic [AW:0]    count,  count_n;
    logic           do_write, do_read;

    // 狀態旗標（以當拍 count 計）
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // 允許條件（gating）
    // 滿格但同拍有讀 → 可寫（釋出一格）
    assign do_write = write_en && (count != DEPTH || read_en);
    // 空但同拍有寫 → 可讀（FWFT 直通）
    assign do_read  = read_en  && (count != 0     || write_en);

    // ★ FWFT 組合輸出：空+同拍RW直通 write_data，其餘讀 mem[rd_ptr]
    assign read_data = (empty && read_en && write_en) ? write_data
                                                      : mem[rd_ptr];

    // 下一拍狀態（一定要先給預設值，再依 do_* 覆蓋）
    always_comb begin
        // 預設保持
        wr_ptr_n = wr_ptr;
        rd_ptr_n = rd_ptr;

        // 單一公式計數（避免用未定義的 count_n 做運算）
        count_n  = count + (do_write ? 1 : 0) - (do_read ? 1 : 0);

        // 指標前進
        if (do_write)
            wr_ptr_n = (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1;

        if (do_read)
            rd_ptr_n = (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1;
    end

    // 時序更新：寫入記憶體 + 狀態暫存
    always_ff @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
            // full/empty 是組合線，在這裡不用另外清
        end else begin
            if (do_write) begin
                // 建議使用「當拍 wr_ptr」地址寫入（read-before-write 推理清楚）
                mem[wr_ptr] <= write_data;
            end

            wr_ptr <= wr_ptr_n;
            rd_ptr <= rd_ptr_n;
            count  <= count_n;
        end
    end

endmodule

// FO (IPF144): 0: Initiating shutdown of proof [125.46 s]
