#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
i=0
while [ $i -lt 12 ]; do
  rd $B/capacity; c=$v
  rd $B/current_now; a=$v
  rd $B/voltage_now; vv=$v
  rd $C/voltage_now; vb=$v
  rd $O/voocchg_ing; po=$v
  rd $O/bcc_current; bc=$v
  rd $B/temp; t=$v
  echo "cap=$c cur=$a volt=$vv vbus=$vb vooc=$po bcc=$bc temp=$t"
  i=$((i+1)); sleep 5
done
