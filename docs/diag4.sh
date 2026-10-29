#!/system/bin/sh
B=/sys/class/power_supply/battery
O=/sys/class/oplus_chg/battery
AC=/sys/class/power_supply/ac
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
rd $AC/online; echo "ac_online=$v (0=已拔出)"
echo "=== 静置电压回落曲线 (每 5s, 共 75s) ==="
i=0
while [ $i -lt 15 ]; do
  rd $B/capacity;    cap=$v
  rd $B/current_now; cn=$v
  rd $B/voltage_now; vo=$v
  rd $B/temp;        tp=$v
  rd $O/chip_soc;    cs=$v
  rd $O/battery_soh; soh=$v
  rd $O/battery_rm;  rm=$v
  echo "t=$((i*5))s cap=$cap chip_soc=$cs cur=$cn volt=$vo temp=$tp soh=$soh rm=$rm"
  i=$((i+1)); sleep 5
done
