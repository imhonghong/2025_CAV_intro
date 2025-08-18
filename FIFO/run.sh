#!/bin/bash

TOP=fifo16x8
TB=tb_fifo16x8
OUT=simv
FSDB=${TOP}.fsdb

# 編譯 (啟用 FSDB 支援)
vcs ${TOP}.sv ${TB}.sv \
    -sverilog -full64 -debug_all -kdb +vcs+fsdb \
    -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
       ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a
    #-o ${OUT}

# 執行模擬
./${OUT}

# 檢查 FSDB 檔案
if [ -f "${FSDB}" ]; then
    echo "✅ 模擬完成，已產生 ${FSDB}"
    # 自動開啟 nWave
    # nWave ${FSDB} &
else
    echo "❌ 沒有找到 ${FSDB}，請確認 testbench 中有呼叫 \$fsdbDumpfile / \$fsdbDumpvars"
fi
