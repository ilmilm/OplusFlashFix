#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
echo "=== 恢复次数 ==="
grep -c "触发重协商" $M/log.txt
echo "=== 最近恢复记录 ==="
grep -E "触发重协商|重协商结果" $M/log.txt | tail -8
echo "=== 当前 ==="
rd $B/capacity; echo "cap=$v"
rd $B/current_now; echo "cur=$v"
rd $C/voltage_now; echo "vbus=$v"
rd $O/voocchg_ing; echo "vooc=$v"
rd $B/temp; echo "temp=$v"
