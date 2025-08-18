clear -all
check_cov -init -type all

# for `JS3_*
jasper_scoreboard_3 -init

analyze -sv ./src/fifo16x8.sv
analyze -sv ./prop/jasper_sb_3.sv
elaborate -top TOP

clock clk
reset ~rstN

prove -all
