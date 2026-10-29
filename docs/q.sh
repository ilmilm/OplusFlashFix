#!/system/bin/sh
M=/data/adb/modules/oplus_flash_fix
echo "=== 手机上的配置 ==="
grep -E "STOP_AT_PERCENT|RECOVER_MAX_PERCENT|ENABLE|TARGET_BCC_MA" $M/config.sh
echo "=== 进程常驻时长 vs 开机时长 ==="
ps -A -o PID,PPID,ELAPSED,ARGS | grep oplus_flash | grep -v grep
echo -n "uptime: "; uptime
echo "=== 日志里最近一次 待机/开始 切换 ==="
grep -E "待机|工作中" $M/log.txt | tail -4
