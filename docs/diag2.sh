#!/system/bin/sh
O=/sys/class/oplus_chg/battery
B=/sys/class/power_supply/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
echo "=== 电量计数据 ==="
for n in chip_soc battery_fcc battery_cc battery_rm design_capacity battery_soh soh_report aging_ffc_data bcc_current; do
  rd $O/$n; echo "$n = $v"
done
echo "=== battery class ==="
for n in capacity charge_now charge_full charge_full_design voltage_now current_now temp health; do
  rd $B/$n; echo "$n = $v"
done
echo "=== 内阻推算 (每2秒, 5次) ==="
i=0
while [ $i -lt 5 ]; do
  rd $B/current_now; cn=$v
  rd $B/voltage_now; vo=$v
  rd $O/voocchg_ing; po=$v
  rd /sys/class/power_supply/mtk-master-charger/voltage_now; vb=$v
  echo "cur=$cn volt=$vo vooc=$po vbus=$vb"
  i=$((i+1)); sleep 2
done
