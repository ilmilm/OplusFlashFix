#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
snap() {
  rd $B/current_now; a=$v
  rd $C/voltage_now; vb=$v
  rd $O/voocchg_ing; po=$v
  rd $B/capacity; c=$v
  echo "  $1 cur=$a vbus=$vb vooc=$po cap=$c"
}
snap START
echo "=== stop_charging_enable: 1 (停充?) 保持 3s ==="
echo 1 > $O/stop_charging_enable 2>/dev/null && echo "  w1 ok" || echo "  w1 FAIL"
i=0; while [ $i -lt 3 ]; do snap "s$((i*1))s"; i=$((i+1)); sleep 1; done
echo "=== 恢复 0 ==="
echo 0 > $O/stop_charging_enable 2>/dev/null && echo "  w0 ok" || echo "  w0 FAIL"
i=0; while [ $i -lt 8 ]; do snap "r$((i*2))s"; i=$((i+1)); sleep 2; done
echo "=== mmi_charging_enable: 0 保持 2s 再 1 ==="
echo 0 > $O/mmi_charging_enable 2>/dev/null && echo "  m0 ok" || echo "  m0 FAIL"
sleep 2
echo 1 > $O/mmi_charging_enable 2>/dev/null && echo "  m1 ok" || echo "  m1 FAIL"
i=0; while [ $i -lt 8 ]; do snap "m$((i*2))s"; i=$((i+1)); sleep 2; done
