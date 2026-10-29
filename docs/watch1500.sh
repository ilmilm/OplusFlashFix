#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
U=/sys/class/oplus_chg/usb
AC=/sys/class/power_supply/ac
OUT=/data/local/tmp/t1500.csv
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
echo "i,cap,cur,volt,vbus,temp,vooc,fct,bcc" > $OUT
i=0
while [ $i -lt 200 ]; do
  rd $AC/online; ac=$v
  [ "$ac" = "1" ] && break
  i=$((i+1)); sleep 2
done
echo "plugged=$i" >> $OUT
i=0
while [ $i -lt 30 ]; do
  rd $B/capacity;      c=$v
  rd $B/current_now;   a=$v
  rd $B/voltage_now;   vv=$v
  rd $C/voltage_now;   vb=$v
  rd $B/temp;          t=$v
  rd $O/voocchg_ing;   po=$v
  rd $U/fast_chg_type; f=$v
  rd $O/bcc_current;   bc=$v
  echo "$i,$c,$a,$vv,$vb,$t,$po,$f,$bc" >> $OUT
  i=$((i+1)); sleep 3
done
echo DONE >> $OUT
