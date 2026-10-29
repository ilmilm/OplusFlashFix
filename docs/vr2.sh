#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 进程(含父进程) ==="
ps -A -o PID,PPID,ARGS 2>/dev/null | grep oplus_flash | grep -v grep
echo "=== 进程数 ==="
pgrep -f oplus_flash_fix | wc -l
echo "=== 日志启动行 ==="
grep "start v" $M/log.txt | tail -2
echo "=== 日志尾部 ==="
tail -4 $M/log.txt
echo "=== bcc ==="
cat /sys/class/oplus_chg/battery/bcc_current 2>/dev/null
