module SB3(
    input clk,
    input rstN,
    input input_vld,   // = write_en && (!full || read_en)
    input output_vld,  // = read_en  && (!empty || write_en)
    input [31:0] din,
    input [31:0] dout
);

  jasper_scoreboard_3 #(
    .CHUNK_WIDTH(16),
    .IN_CHUNKS(1),
    .OUT_CHUNKS(1),
    .SINGLE_CLOCK(1),
    .ORDERING(`JS3_IN_ORDER),
    .MAX_PENDING(8)
  ) sb (
    .rstN          (rstN),
    .incoming_clk  (clk),
    .outgoing_clk  (clk),
    .clk (clk),
    .incoming_vld  (input_vld),
    .incoming_data (din),
    .outgoing_vld  (output_vld),
    .outgoing_data (dout)
  );

endmodule

bind TOP SB3 SB3_i(
    .clk            (clk),
    .rstN           (rstN),
    .input_vld      (write_en && (!full  || read_en) ),
    .output_vld     (read_en  && (!empty || write_en) ),
    .din            (write_data),
    .dout           (read_data)
    );



