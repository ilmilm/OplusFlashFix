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

# 充到该百分比后停止钉电流(不再干预), 掉回以下自动恢复; 0=不限制
STOP_AT_PERCENT=80

LOG_ENABLE=1

# ---- 回落自动恢复 ----
# 1=启用: 检测到 vooc=0 且电流低于 RECOVER_CUR 时, 用 mmi_charging_enable 0->1 强制重协商
RECOVER=1
# 低于该电流(mA)视为已回落到保底档
RECOVER_CUR=800
# 电量超过该值不再尝试恢复(高电量本身就跑不动快充)
RECOVER_MAX_PERCENT=58
# 连续满足条件多少次(每次约0.35s)才触发, 3 约等于 1 秒
RECOVER_CONFIRM=3
# 插上后多少 tick 内不触发(约30 tick = 10秒), 避免打断正常协商
RECOVER_GRACE_TICKS=30
# 两次恢复尝试的最小间隔 tick(约70 tick = 25秒)
RECOVER_COOLDOWN_TICKS=70
# 连续失败多少次后放弃(本次插入不再尝试, 拔插重置)
RECOVER_MAX_FAIL=3
