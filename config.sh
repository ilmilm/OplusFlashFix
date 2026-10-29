# ===== OplusFlashFix v2.0 配置 =====
ENABLE=1

# 模式: vguard=电压闭环(推荐) | fixed=固定值 | table=静态分档
MODE=fixed

# fixed / table 模式用
TARGET_BCC_MA=1500
CAP_TIERS="15:4000 30:3800 45:3400 60:3000 75:2200 90:1500 101:900"

# ---- 电压闭环参数 (单位 mV / mA) ----
# 实测跳闸点约 4539mV, 留 80mV 余量作为上限
V_HIGH=4460
V_LOW=4390
MAX_MA=3000
MIN_MA=500
START_MA=1500
# 电压超上限时降多少 / 电压有空间时升多少
STEP_DOWN=200
STEP_UP=100
# 每隔多少毫秒调整一次
ADJ_MS=1500

# 温度降档与停止
TEMP_DERATE=380
TEMP_LIMIT=430

# 充到该百分比停止干预 (0=关闭)
STOP_AT_PERCENT=0

LOG_ENABLE=1
