#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 脚本间隔 ==="
grep -n "sleep 0" $M/service.sh
echo "=== 重载周期 ==="
grep -n "cnt % " $M/service.sh
echo "=== 配置 ==="
grep -E "^MODE=|^TARGET_BCC_MA=" $M/config.sh
echo "=== 进程 ==="
pgrep -f oplus_flash_fix | tr "\n" " "; echo
echo "=== 当前 ==="
echo -n "bcc="; cat /sys/class/oplus_chg/battery/bcc_current 2>/dev/null
echo -n "ac="; cat /sys/class/power_supply/ac/online
