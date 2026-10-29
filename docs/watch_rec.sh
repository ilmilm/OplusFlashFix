#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
AC=/sys/class/power_supply/ac
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
i=0
while [ $i -lt 12 ]; do
  rd $AC/online; ac=$v
  rd $B/capacity; c=$v
  rd $B/current_now; a=$v
  rd $B/voltage_now; vv=$v
  rd $C/voltage_now; vb=$v
  rd $O/voocchg_ing; po=$v
  echo "t=$((i*5))s ac=$ac cap=$c cur=$a volt=$vv vbus=$vb vooc=$po"
  i=$((i+1)); sleep 5
done
echo "=== 恢复相关日志 ==="
grep -E "回落|重协商" /data/adb/modules/oplus_flash_fix/log.txt | tail -5 || echo "(尚无恢复记录)"
echo "=== 日志尾部 ==="
tail -4 /data/adb/modules/oplus_flash_fix/log.txt
