#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 开机 ==="
uptime
echo "=== 版本/位置 ==="
grep -E "^version=" $M/module.prop
echo "modules_update: [$(ls /data/adb/modules_update/ 2>/dev/null | tr "\n" " ")]"
echo "=== 进程(PPID) ==="
ps -A -o PID,PPID,ARGS 2>/dev/null | grep oplus_flash | grep -v grep
echo "=== 启动日志 ==="
grep "start v" $M/log.txt | tail -1
echo "=== 恢复相关配置 ==="
grep -E "^RECOVER" $M/config.sh
echo "=== 当前状态 ==="
echo -n "ac="; cat /sys/class/power_supply/ac/online
echo -n "cap="; cat /sys/class/power_supply/battery/capacity
echo -n "cur="; cat /sys/class/power_supply/battery/current_now
echo -n "vooc="; cat /sys/class/oplus_chg/battery/voocchg_ing
echo -n "bcc="; cat /sys/class/oplus_chg/battery/bcc_current
