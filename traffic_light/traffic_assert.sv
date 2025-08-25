// traffic_assert.sv
`timescale 1ns/1ps

module traffic_assert
(
    input logic clk,
    input logic rst,
    input logic Road1_G, Road1_Y, Road1_R,
    input logic Road2_G, Road2_Y, Road2_R,
    input logic Walk_G, Walk_R
);

    // -------- 基本設定 --------
    // 假設 rst 為同步 reset，disable iff (rst) 在各 property 上屏蔽 reset 期間
    // 若你的 rst 為低有效，請把條件改成 disable iff (!rst)

    // ===== 1) 路燈 one-hot =====
    // 每條車道同時只允許一盞燈亮（G/Y/R 其一）
    assert_onehot_r1: assert property (@(posedge clk) disable iff (rst)
        (Road1_G + Road1_Y + Road1_R) == 1
    ) else $error("Road1 G/Y/R not one-hot");
    cover_onehot_r1: cover property (@(posedge clk) disable iff (rst)
        (Road1_G + Road1_Y + Road1_R) == 1
    );

    assert_onehot_r2: assert property (@(posedge clk) disable iff (rst)
        (Road2_G + Road2_Y + Road2_R) == 1
    ) else $error("Road2 G/Y/R not one-hot");
    cover_onehot_r2: cover property (@(posedge clk) disable iff (rst)
        (Road2_G + Road2_Y + Road2_R) == 1
    );

    // 行人燈互斥（不允許同時 Walk_G 與 Walk_R 皆為 1）；
    // 允許兩者同為 0（對應你設計在閃爍 OFF 的半拍）
    assert_walk_mutex: assert property (@(posedge clk) disable iff (rst)
        !(Walk_G && Walk_R)
    ) else $error("Walk_G and Walk_R cannot be 1 at the same time");
    cover_walk_mutex: cover property (@(posedge clk) disable iff (rst)
        !(Walk_G && Walk_R)
    );

    // ===== 2) 衝突避免 =====
    // 不得雙向綠燈同時亮
    assert_no_both_green: assert property (@(posedge clk) disable iff (rst)
        !(Road1_G && Road2_G)
    ) else $error("Both roads green simultaneously!");
    cover_no_both_green: cover property (@(posedge clk) disable iff (rst)
        !(Road1_G && Road2_G)
    );

    // 黃燈不會雙向同時亮
    assert_no_both_yellow: assert property (@(posedge clk) disable iff (rst)
        !(Road1_Y && Road2_Y)
    ) else $error("Both roads yellow simultaneously!");
    cover_no_both_yellow: cover property (@(posedge clk) disable iff (rst)
        !(Road1_Y && Road2_Y)
    );
    // ===== 3) 行人燈與車燈關聯 =====
    // 只要行人綠燈 ON，兩條車道皆應為紅燈（包含連續行走與閃爍期間的 ON 半拍）
    assert_walkG_roads_red: assert property (@(posedge clk) disable iff (rst)
        (Walk_G) |-> (Road1_R && Road2_R)
    ) else $error("Walk_G requires both roads red");

    // 若任一車道為綠燈，行人必須不可通行（Walk_G=0 且 Walk_R=1）
    assert_green_blocks_walk: assert property (@(posedge clk) disable iff (rst)
        (Road1_G || Road2_G) |-> (!Walk_G && Walk_R)
    ) else $error("When any road is green, Walk must be R only");

    // 黃燈期間也不得給行人通行（保持 Walk_R=1, Walk_G=0）
    assert_yellow_blocks_walk: assert property (@(posedge clk) disable iff (rst)
        (Road1_Y || Road2_Y) |-> (!Walk_G && Walk_R)
    ) else $error("When any road is yellow, Walk must be R only");

    // 閃爍期間（Walk_R=0）不應同時開放車流（兩路仍須紅燈）
    assert_blink_roads_red: assert property (@(posedge clk) disable iff (rst)
        (Walk_R == 0) |-> (Road1_R && Road2_R)
    ) else $error("During walk blinking (Walk_R=0), both roads must stay red");

    // ===== 4) 轉換合法性（序列） =====
    // 綠 ->（收燈）-> 黃：當某路綠燈熄滅的那拍，該路黃燈應點亮（不直接跳紅）
    assert_g2y_r1: assert property (@(posedge clk) disable iff (rst)
        ($fell(Road1_G)) |-> Road1_Y
    ) else $error("Road1 should transition G->Y, not G->R");

    assert_g2y_r2: assert property (@(posedge clk) disable iff (rst)
        ($fell(Road2_G)) |-> Road2_Y
    ) else $error("Road2 should transition G->Y, not G->R");

    // 黃 -> 紅：當某路黃燈熄滅的那拍，該路紅燈應點亮（不直接跳綠）
    assert_y2r_r1: assert property (@(posedge clk) disable iff (rst)
        ($fell(Road1_Y)) |-> Road1_R
    ) else $error("Road1 should transition Y->R");

    assert_y2r_r2: assert property (@(posedge clk) disable iff (rst)
        ($fell(Road2_Y)) |-> Road2_R
    ) else $error("Road2 should transition Y->R");

    // 紅 -> 綠：當某路紅燈熄滅，代表輪到它放行，該路綠燈應立即點亮
    assert_r2g_r1: assert property (@(posedge clk) disable iff (rst)
        ($fell(Road1_R)) |-> Road1_G
    ) else $error("Road1 should transition R->G");

    assert_r2g_r2: assert property (@(posedge clk) disable iff (rst)
        ($fell(Road2_R)) |-> Road2_G
    ) else $error("Road2 should transition R->G");
    
    localparam int CYCLE = 128;
    localparam int G_LEN=40, Y_LEN=5, GAP_LEN=2, WG_LEN=26, BLK_LEN=6;

    sequence STEADY_WALK;
        (Road1_R && Road2_R && Walk_G && !Walk_R)[*WG_LEN];
    endsequence

    sequence BLINK_ANY;
        (Road1_R && Road2_R && !Walk_R && (Walk_G != $past(Walk_G)))[*BLK_LEN];
    endsequence

    sequence r1_phase;
        (Road1_G && Road2_R && !Walk_G && Walk_R)[*G_LEN] ##1
        (Road1_Y && Road2_R && !Walk_G && Walk_R)[*Y_LEN] ##1
        (Road1_R && Road2_R && !Walk_G && Walk_R)[*GAP_LEN];
    endsequence

    sequence r2_phase;
        (Road2_G && Road1_R && !Walk_G && Walk_R)[*G_LEN] ##1
        (Road2_Y && Road1_R && !Walk_G && Walk_R)[*Y_LEN] ##1
        (Road1_R && Road2_R && !Walk_G && Walk_R)[*GAP_LEN];
    endsequence

    sequence GAP_RR; // 兩拍雙紅 + Walk_R=1 的間隔
        (Road1_R && Road2_R && !Walk_G && Walk_R)[*GAP_LEN];
    endsequence

    // 只在「剛進入行人穩定綠」那次 $rose(Walk_G) 觸發：前一拍 Walk_R 必為 1
    assert_walk_green: assert property (@(posedge clk) disable iff (rst)
        ($rose(Walk_G) && $past(Walk_R)) |->
            STEADY_WALK ##1
            BLINK_ANY   ##1
            GAP_RR
    );

    assert_seq_cycle: assert property (@(posedge clk) disable iff (rst)
        $rose(Road1_G) |->
            r1_phase ##1 r2_phase ##1 STEADY_WALK ##1 BLINK_ANY ##1 GAP_RR ##1
            $rose(Road1_G)
    );

    // ===== 6) Cover（幫助觀察關鍵情境是否被激發） =====
    // 觀察行人通行階段出現
    cover_walkG: cover property (@(posedge clk) disable iff (rst)
        Walk_G && Road1_R && Road2_R
    );

    // 觀察兩路交替：Road1 綠 -> Road1 黃 -> Road1 紅 -> Road2 綠
    cover_r1_to_r2: cover property (@(posedge clk) disable iff (rst)
        $rose(Road1_G)
            ##[1:$] $rose(Road1_Y)
            ##[1:$] $rose(Road1_R)
            ##[1:$] $rose(Road2_G)
    );

    // 紅燈亮起後，CYCLE 內一定會等到綠燈再亮起（Road1/Road2 各一條）
    cover_R1_G_cycle: cover property (@(posedge clk) disable iff (rst)
        $rose(Road1_R) |-> ##[1:CYCLE] $rose(Road1_G));

    cover_R2_G_cycle: cover property (@(posedge clk) disable iff (rst)
        $rose(Road2_R) |-> ##[1:CYCLE] $rose(Road2_G));

    // 例：R1 綠 40 拍後必轉黃；期間 R2=R、Walk=R
    cover_R1_G_40sec: cover property (@(posedge clk) disable iff (rst)
        $rose(Road1_G) |->
            (Road1_G && Road2_R && !Walk_G && Walk_R)[*G_LEN] ##1 Road1_Y);

    // 例：R1 黃 5 拍 → 2 拍雙紅 → R2 綠起
    cover_R1_Y_5sec: cover property (@(posedge clk) disable iff (rst)
        $rose(Road1_Y) |->
            (Road1_Y && Road2_R && !Walk_G && Walk_R)[*Y_LEN] ##1
            (Road1_R && Road2_R && !Walk_G && Walk_R)[*GAP_LEN] ##1
            $rose(Road2_G));

endmodule
