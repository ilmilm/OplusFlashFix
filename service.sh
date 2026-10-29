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
C=/sys/class/power_supply/mtk-master-charger
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

log "start v2.2 mode=${MODE} target=${TARGET_BCC_MA} recover=${RECOVER}"

T=${TARGET_BCC_MA:-1500}
cnt=0
lastw=""
lowcnt=0
lastrec=0
prevac=0
plugtick=0

while true; do
  cnt=$((cnt+1))
  if [ $((cnt % 20)) -eq 0 ]; then
    [ -f "$MODDIR/config.sh" ] && . "$MODDIR/config.sh"
  fi
  [ "${ENABLE:-1}" = "1" ] || { sleep 2; continue; }

  rd $AC/online; ac=$v
  if [ "$ac" != "1" ]; then
    prevac=0; lowcnt=0
    [ "$lastw" != "unplug" ] && { log "未接入电源, 待机"; lastw="unplug"; }
    sleep 1; continue
  fi
  if [ "$prevac" != "1" ]; then plugtick=$cnt; lowcnt=0; prevac=1; fi

  rd $B/capacity;    cap=$v
  rd $B/temp;        tp=$v
  rd $B/current_now; cn=$v
  rd $B/voltage_now; vo=$v
  rd $O/voocchg_ing; po=$v
  case "$cap" in ""|*[!0-9]*) cap=0 ;; esac
  case "$tp"  in ""|*[!0-9]*) tp=0 ;; esac
  case "$vo"  in ""|*[!0-9]*) vo=0 ;; esac
  cn=${cn#-}
  case "$cn"  in ""|*[!0-9]*) cn=0 ;; esac
  case "$po"  in ""|*[!0-9]*) po=9 ;; esac

  if [ "$tp" -ge "${TEMP_LIMIT:-430}" ]; then
    [ "$lastw" != "hot" ] && { log "温度 ${tp} >= ${TEMP_LIMIT}, 停止干预"; lastw="hot"; }
    sleep 1; continue
  fi
  sp=${STOP_AT_PERCENT:-0}
  if [ "$sp" -gt 0 ] && [ "$cap" -ge "$sp" ]; then
    [ "$lastw" != "stop" ] && { log "电量 ${cap}% >= ${sp}%, 停止干预"; lastw="stop"; }
    sleep 1; continue
  fi

  case "${MODE:-fixed}" in
    table) T=$(pick_table $cap) ;;
    vguard)
      if [ "$vo" -ge "${V_HIGH:-4460}" ]; then T=$((T - ${STEP_DOWN:-200}));
      elif [ "$vo" -le "${V_LOW:-4390}" ] && [ "$cn" -ge 300 ] && [ "$T" -lt "${MAX_MA:-3000}" ]; then T=$((T + ${STEP_UP:-100})); fi
      if [ "$cn" -lt 200 ]; then T=${START_MA:-1500}; fi
      [ "$T" -gt "${MAX_MA:-3000}" ] && T=${MAX_MA:-3000}
      [ "$T" -lt "${MIN_MA:-500}" ] && T=${MIN_MA:-500}
      ;;
    *) T=${TARGET_BCC_MA:-1500} ;;
  esac

  OUT=$T
  if [ "$tp" -ge "${TEMP_DERATE:-380}" ]; then OUT=$((T / 2)); fi
  RAW=$((OUT / 100))
  [ "$RAW" -lt 1 ] && RAW=1
  echo "$RAW" > $O/bcc_current 2>/dev/null || { [ "$lastw" != "wf" ] && { log "写 bcc_current 失败"; lastw="wf"; }; }
  CCMAX=$((OUT * 1000))
  [ "$CCMAX" -gt 0 ] && echo "$CCMAX" > $C/constant_charge_current_max 2>/dev/null

  if [ "$lastw" != "run" ] || [ $((cnt % 30)) -eq 0 ]; then
    log "cap=${cap}% 目标=${OUT}mA 实测=${cn}mA 端压=${vo}mV vooc=${po} temp=$tp"
    lastw="run"
  fi

  # ===== 回落自动恢复 =====
  # 条件: 已充电超过宽限时间, 当前只走保底档(vooc=0 且电流 < 800mA), 电量未过高
  if [ "${RECOVER:-1}" = "1" ] && [ "$po" = "0" ] && [ "$cn" -lt "${RECOVER_CUR:-800}" ] && [ "$cap" -lt "${RECOVER_MAX_PERCENT:-80}" ]; then
    if [ $((cnt - plugtick)) -gt "${RECOVER_GRACE_TICKS:-30}" ]; then
      lowcnt=$((lowcnt+1))
      if [ "$lowcnt" -ge "${RECOVER_CONFIRM:-3}" ] && [ $((cnt - lastrec)) -ge "${RECOVER_COOLDOWN_TICKS:-70}" ]; then
        log "检测到回落(vooc=0, 实测=${cn}mA, cap=${cap}%), 触发重协商"
        echo 0 > $O/mmi_charging_enable 2>/dev/null
        sleep 2
        echo 1 > $O/mmi_charging_enable 2>/dev/null
        lastrec=$cnt
        lowcnt=0
        sleep 3
        rd $O/voocchg_ing; nv=$v
        rd $B/current_now; nc=$v
        log "重协商结果: vooc=$nv 电流=${nc}mA"
      fi
    fi
  else
    lowcnt=0
  fi

  sleep 0.3
done
