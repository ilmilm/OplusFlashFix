#!/system/bin/sh
B=/sys/class/power_supply/battery
C=/sys/class/power_supply/mtk-master-charger
O=/sys/class/oplus_chg/battery
U=/sys/class/oplus_chg/usb
AC=/sys/class/power_supply/ac
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }
echo "=== 开机时长 ==="
uptime
echo "=== 模块目录 ==="
ls /data/adb/modules/oplus_flash_fix/ 2>/dev/null | tr "\n" " "; echo
echo "=== 守护进程 ==="
pgrep -f oplus_flash_fix || echo "无进程"
echo "=== 充电状态 ==="
rd $AC/online;       echo "ac_online=$v"
rd $B/capacity;      echo "电量=$v"
rd $B/status;        echo "状态=$v"
rd $B/current_now;   echo "电流=$v mA"
rd $B/voltage_now;   echo "端电压=$v mV"
rd $C/voltage_now;   echo "VBUS=$v mV"
rd $B/temp;          echo "温度=$v (0.1C)"
rd $U/fast_chg_type; echo "快充类型=$v"
rd $O/voocchg_ing;   echo "VOOC进行中=$v"
rd $O/bcc_current;   echo "bcc_current=$v"
rd $O/battery_soh;   echo "SoH=$v"
echo "=== 模块日志尾部 ==="
tail -8 /data/adb/modules/oplus_flash_fix/log.txt 2>/dev/null || echo "无日志"
