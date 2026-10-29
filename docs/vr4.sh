#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 开机 ==="
uptime
echo "=== 版本 ==="
grep -E "^version=" $M/module.prop
echo "modules_update: [$(ls /data/adb/modules_update/ 2>/dev/null | tr "\n" " ")]"
echo "=== 进程 ==="
ps -A -o PID,PPID,ARGS 2>/dev/null | grep oplus_flash | grep -v grep
echo "=== 启动日志 ==="
grep "start v" $M/log.txt | tail -1
echo "=== 恢复配置 ==="
grep -E "^RECOVER" $M/config.sh
echo "=== 当前 ==="
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
rd $B/capacity; echo "cap=$v"
rd $B/current_now; echo "cur=$v"
rd $C/voltage_now; echo "vbus=$v"
rd $O/voocchg_ing; echo "vooc=$v"
rd $O/bcc_current; echo "bcc=$v"
