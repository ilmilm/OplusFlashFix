#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 日志启动行 ==="
grep "start v" $M/log.txt | tail -3
echo "=== 最近日志 ==="
tail -3 $M/log.txt
echo "=== 脚本是否含热重载 ==="
grep -c "cnt % 8" $M/service.sh
grep "start v" $M/service.sh
echo "=== 进程 cmdline ==="
for p in $(pgrep -f oplus_flash_fix); do
  echo -n "pid=$p cmd="
  tr "\0" " " < /proc/$p/cmdline 2>/dev/null
  echo
done
echo "=== 配置 ==="
grep -E "^MODE=|^TARGET_BCC_MA=" $M/config.sh
