#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
U=/sys/class/oplus_chg/usb
AC=/sys/class/power_supply/ac
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
snap() {
  rd $B/capacity; c=$v
  rd $B/current_now; a=$v
  rd $C/voltage_now; vb=$v
  rd $O/voocchg_ing; po=$v
  echo "  $1 cap=$c cur=$a vbus=$vb vooc=$po"
}
snap BEFORE
echo "=== otg_switch 权限 ==="
ls -l $U/otg_switch
echo "=== 翻转 otg_switch ==="
echo 1 > $U/otg_switch 2>/dev/null && echo "  set 1 ok" || echo "  set 1 FAIL"
sleep 2
echo 0 > $U/otg_switch 2>/dev/null && echo "  set 0 ok" || echo "  set 0 FAIL"
echo "=== 恢复后观察 24s ==="
i=0
while [ $i -lt 12 ]; do
  snap "t=$((i*2))s"
  i=$((i+1)); sleep 2
done
