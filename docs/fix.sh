#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 设置 1500 ==="
sed -i "s|^TARGET_BCC_MA=.*|TARGET_BCC_MA=1500|" $M/config.sh
grep -E "^MODE=|^TARGET_BCC_MA=" $M/config.sh
echo "=== 去重守护进程 (只留最早一个) ==="
pids=$(pgrep -f oplus_flash_fix)
first=$(echo "$pids" | head -1)
echo "keep=$first  all=[$pids]"
for p in $pids; do
  [ "$p" = "$first" ] && continue
  kill $p 2>/dev/null && echo "killed $p"
done
sleep 2
echo "=== 剩余 ==="
pgrep -f oplus_flash_fix | tr "\n" " "; echo
echo "=== 当前状态 ==="
echo -n "bcc="; cat /sys/class/oplus_chg/battery/bcc_current 2>/dev/null
echo -n "ac="; cat /sys/class/power_supply/ac/online
echo -n "cap="; cat /sys/class/power_supply/battery/capacity
