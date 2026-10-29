#!/system/bin/sh
B=/sys/class/power_supply/battery
O=/sys/class/oplus_chg/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
echo "=== 90s 趋势 (每 6s) ==="
i=0
while [ $i -lt 15 ]; do
  rd $B/capacity;    cap=$v
  rd $B/current_now; cn=$v
  rd $B/voltage_now; vo=$v
  rd $O/voocchg_ing; po=$v
  rd $O/chip_soc;    cs=$v
  rd $O/battery_rm;  rm=$v
  echo "t=$((i*6))s cap=$cap chip_soc=$cs cur=$cn volt=$vo vooc=$po rm=$rm"
  i=$((i+1)); sleep 6
done
echo "=== dmesg 电量计/FFC ==="
dmesg 2>/dev/null | grep -i -E "bq28|bq27|gauge|ffc|soh|recal|age" | tail -12
