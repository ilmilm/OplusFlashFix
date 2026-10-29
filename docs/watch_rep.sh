#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
i=0
while [ $i -lt 18 ]; do
  rd $B/capacity; c=$v
  rd $B/current_now; a=$v
  rd $C/voltage_now; vb=$v
  rd $O/voocchg_ing; po=$v
  echo "t=$((i*8))s cap=$c cur=$a vbus=$vb vooc=$po"
  i=$((i+1)); sleep 8
done
echo "=== 所有恢复记录 ==="
grep -cE "触发重协商" /data/adb/modules/oplus_flash_fix/log.txt
grep -E "触发重协商|重协商结果" /data/adb/modules/oplus_flash_fix/log.txt | tail -6
