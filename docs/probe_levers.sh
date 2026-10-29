#!/system/bin/sh
O=/sys/class/oplus_chg/battery
B=/sys/class/power_supply/battery
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
echo "=== 当前 bcc_parms ==="
rd $O/bcc_parms; echo "bcc_parms = $v"
echo "=== 电荷泵驱动绑定情况 ==="
for d in sc8571-master sc8571-slave; do
  echo -n "$d: "; ls /sys/bus/i2c/drivers/$d/ 2>/dev/null | tr "\n" " "; echo
done
echo "=== 快充协议 IC ==="
echo -n "sy6610-fastcg: "; ls /sys/bus/i2c/drivers/sy6610-fastcg/ 2>/dev/null | tr "\n" " "; echo
echo "=== 可写降级开关 ==="
for n in cool_down normal_cool_down charge_technology stop_charging_enable; do
  printf "%-22s %s\n" "$n" "$(ls -l $O/$n 2>/dev/null | cut -c1-10)"
done
echo "=== 当前配置 ==="
grep -E "^MODE=|^TARGET_BCC_MA=" /data/adb/modules/oplus_flash_fix/config.sh
echo "=== 当前状态 ==="
rd $B/capacity; echo "cap=$v"
rd $B/voltage_now; echo "volt=$v"
