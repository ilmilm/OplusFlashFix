#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
U=/sys/class/oplus_chg/usb
AC=/sys/class/power_supply/ac
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
echo "=== 等待接入 (最多 60s) ==="
i=0
while [ $i -lt 30 ]; do
  rd $AC/online; ac=$v
  [ "$ac" = "1" ] && { echo "已接入 (t=$((i*2))s)"; break; }
  i=$((i+1)); sleep 2
done
rd $AC/online; echo "ac_online=$v"
echo "=== 接入后 60s 采样 (每 3s) ==="
i=0
while [ $i -lt 20 ]; do
  rd $B/capacity;      cap=$v
  rd $B/current_now;   cn=$v
  rd $B/voltage_now;   vo=$v
  rd $C/voltage_now;   vb=$v
  rd $O/voocchg_ing;   po=$v
  rd $U/fast_chg_type; f=$v
  rd $O/bcc_current;   bc=$v
  echo "t=$((i*3))s cap=$cap cur=$cn volt=$vo vbus=$vb vooc=$po fct=$f bcc=$bc"
  i=$((i+1)); sleep 3
done
