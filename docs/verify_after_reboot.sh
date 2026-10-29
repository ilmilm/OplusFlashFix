#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 开机时长 ==="
uptime
echo "=== 模块位置 ==="
ls /data/adb/modules/ | tr "\n" " "; echo
echo "modules_update: $(ls /data/adb/modules_update/ 2>/dev/null | tr "\n" " ")"
echo "=== 模块版本 ==="
grep -E "^version=|^versionCode=" $M/module.prop
echo "=== 配置 ==="
grep -E "^MODE=|^TARGET_BCC_MA=|^TEMP_" $M/config.sh
=== 进程(含父进程) ===
ps -A -o PID,PPID,ARGS 2>/dev/null | grep oplus_flash | grep -v grep
echo "=== 进程数 ==="
pgrep -f oplus_flash_fix | wc -l
echo "=== 日志启动行 ==="
grep "start v" $M/log.txt | tail -2
echo "=== 日志尾部 ==="
tail -3 $M/log.txt
echo "=== 充电状态 ==="
echo -n "cap="; cat /sys/class/power_supply/battery/capacity
echo -n "ac="; cat /sys/class/power_supply/ac/online
echo -n "bcc="; cat /sys/class/oplus_chg/battery/bcc_current
