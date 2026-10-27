#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/config.sh" ] && . "$MODDIR/config.sh"
LOG="$MODDIR/log.txt"
log() { [ "${LOG_ENABLE:-1}" = "1" ] && echo "[$(date "+%m-%d %H:%M")] $*" >> "$LOG"; }

[ -f "$MODDIR/disable" ] && exit 0
n=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $n -lt 150 ]; do sleep 2; n=$((n+1)); done
sleep 3

B=/sys/class/power_supply/battery
O=/sys/class/oplus_chg/battery
AC=/sys/class/power_supply/ac
v=
rd() { v=; read -r v < "$1" 2>/dev/null; }

pick_table() {
  cap=$1; T=""
  for pair in $CAP_TIERS; do
    thr=${pair%%:*}; amt=${pair##*:}
    if [ "$cap" -lt "$thr" ]; then T=$amt; break; fi
  done
  [ -z "$T" ] && T=900
  echo $T
}

log "start v2.0 mode=${MODE} vhigh=${V_HIGH} vlow=${V_LOW} max=${MAX_MA}"

T=${START_MA:-1500}
cnt=0
lastw=""
lastlog=0
while true; do
  cnt=$((cnt+1))
  if [ $((cnt % 8)) -eq 0 ]; then
    [ -f "$MODDIR/config.sh" ] && . "$MODDIR/config.sh"
  fi
  [ "${ENABLE:-1}" = "1" ] || { sleep 2; continue; }

  rd $AC/online; ac=$v
  if [ "$ac" != "1" ]; then
    T=${START_MA:-1500}
    [ "$lastw" != "unplug" ] && { log "未接入电源, 待机"; lastw="unplug"; }
    sleep 1; continue
  fi

  rd $B/capacity;    cap=$v
  rd $B/temp;        tp=$v
  rd $B/current_now; cn=$v
  rd $B/voltage_now; vo=$v
  case "$cap" in ""|*[!0-9]*) cap=0 ;; esac
  case "$tp"  in ""|*[!0-9]*) tp=0 ;; esac
  case "$vo"  in ""|*[!0-9]*) vo=0 ;; esac
  cn=${cn#-}
  case "$cn"  in ""|*[!0-9]*) cn=0 ;; esac

  if [ "$tp" -ge "${TEMP_LIMIT:-430}" ]; then
    [ "$lastw" != "hot" ] && { log "温度 ${tp} >= ${TEMP_LIMIT}, 停止干预"; lastw="hot"; }
    sleep 1; continue
  fi
  sp=${STOP_AT_PERCENT:-0}
  if [ "$sp" -gt 0 ] && [ "$cap" -ge "$sp" ]; then
    [ "$lastw" != "stop" ] && { log "电量 ${cap}% >= ${sp}%, 停止干预"; lastw="stop"; }
    sleep 1; continue
  fi

  case "${MODE:-vguard}" in
    fixed)
      T=${TARGET_BCC_MA:-3000}
      ;;
    table)
      T=$(pick_table $cap)
      ;;
    *)
      # 电压闭环: 端电压高就收, 有空间就放
      if [ "$vo" -ge "${V_HIGH:-4460}" ]; then
        T=$((T - ${STEP_DOWN:-200}))
      elif [ "$vo" -le "${V_LOW:-4390}" ] && [ "$cn" -ge 300 ] && [ "$T" -lt "${MAX_MA:-3000}" ]; then
        T=$((T + ${STEP_UP:-100}))
      fi
      if [ "$cn" -lt 200 ]; then T=${START_MA:-1500}; fi
      [ "$T" -gt "${MAX_MA:-3000}" ] && T=${MAX_MA:-3000}
      [ "$T" -lt "${MIN_MA:-500}" ] && T=${MIN_MA:-500}
      ;;
  esac

  # 温度高时砍半
  OUT=$T
  if [ "$tp" -ge "${TEMP_DERATE:-380}" ]; then OUT=$((T / 2)); fi
  RAW=$((OUT / 100 ))
  [ "$RAW" -lt 1 ] && RAW=1
  echo "$RAW" > $O/bcc_current 2>/dev/null || { [ "$lastw" != "wf" ] && { log "写 bcc_current 失败"; lastw="wf"; }; }

  if [ "$lastw" != "run" ] || [ $((cnt % 10)) -eq 0 ]; then
    log "cap=${cap}% 目标=${OUT}mA 实测=${cn}mA 端压=${vo}mV vbus? temp=$tp"
    lastw="run"
  fi
  sleep 1.5
done
