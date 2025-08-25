#!/bin/bash

# 檔名設定
TOP=traffic
TB=tb
ASSERT=traffic_assert
BIND=bind_traffic
OUT=simv
FSDB=${TOP}.fsdb

# remove old waveform
rm *.fsdb

# 編譯（加入 fsdb 支援）
vcs ${TOP}.v ${TB}.sv  ${ASSERT}.sv ${BIND}.sv \
    -sverilog -full64 -debug_all -kdb +vcs+fsdb \
    -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
    ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a
    #-o ${OUT}

# 執行模擬
./${OUT}

# 如果 fsdb 檔案產生成功，詢問是否開啟 nWave
if [ -f "${FSDB}" ]; then
    echo "✅ 模擬完成，已產生 ${FSDB}"

    # 啟用此行自動開啟 nWave
    # nWave ${FSDB} &
else
    echo "❌ 沒有找到 ${FSDB}，請確認 testbench 中有呼叫 \$fsdbDumpfile"
fi

