# OplusFlashFix

让**电池老化**的 OPPO / 一加 手机在 100W SUPERVOOC（超级闪充）充电头下稳定快充的 KernelSU / Magisk 模块。

> 把 `bcc_current`（电池充电电流上限）钉在电池真正能吃下的档位，避免电流冲得太高导致端电压触顶、保护切断、回落到 5V/0.5A 的 3W 慢充。

**English TL;DR** — On an aged battery (high internal resistance), a 100W SUPERVOOC charger ramps to ~4.3A, the terminal voltage overshoots the protection threshold (~4.54V) within 0.6s, charging aborts and the phone permanently falls back to 5V/0.5A (~3W). This module pins `bcc_current` at 3A so the phone settles on a stable 8.9V / ~2.4-2.9A path (~11-13W) instead. Verified on OnePlus Ace (PGKM10), ColorOS 13.1, KernelSU.

## 问题现象

- 插上 100W 原装头，界面闪一下“超级闪充”就断，之后长期只有 **3W 左右**
- 插 30W 头反而稳定，但只有 1.7A 上下
- 电池健康度低（本例 **SoH 41%**，容量保持 57%）

## 根因（实测，非推测）

用 100ms 粒度记录整次插拔过程，抓到了完整的失效链：

| 时间点 | 电池电流 | 端电压 | `voocchg_ing` | 说明 |
|---|---|---|---|---|
| t+0.0s | -146mA | 3802mV | 1 | 握手成功，滴流 |
| t+0.2s | -2230mA | 3802mV | 1 | 阶跃升流 |
| t+0.8s | -4329mA | 3802mV | 1 | 冲到 4.3A |
| **t+1.6s** | -4329mA | **4539mV** | 1 | 端电压触顶 |
| **t+1.8s** | -260mA → +99mA | 4539mV | **0** | VOOC 被切断，转为放电 |

关键推算：

```
内阻 R = (端电压 - OCV) / 电流
       ≈ (4539mV - 3802mV) / 4.33A
       ≈ 170 mΩ        (健康电池 30~60mΩ)
```

所以 **不是系统故意限速，而是电池物理上吃不下这么大的电流**：电流一大，端电压就顶到保护阈值，保护一动作，充电器退回 5V/0.5A 的默认档，然后手机不再重试。

## 机制

把 `bcc_current` 压到 3A 后：

| `bcc_current` | 手机走的档位 | 结果 |
|---|---|---|
| 6500（默认） | 冲到 4.33A | 跳闸回落，**3W** |
| **3000** | **8.9V / 2.4~2.9A** | **11~13W，131 秒无中断** ✅ |
| 4000 | 切到 11V 档 | 更易跳闸，**2.9W** ❌ |
| 1500 | 不发起 VOOC | 停在 5V/0.575A，**2.9W** ❌ |

注意 `bcc_current` 这个节点的 setter 会把写入值**乘 100**（写 30 实际等于 3000mA），模块内部已做换算。

## 实测曲线

| 电量区间 | 原始状态 | 装模块后 |
|---|---|---|
| 0~50% | 3W，每几秒断一次 | **11~13W 稳定** |
| 50~100% | 2.9W | 2.9W（无改善） |

50% 以上提不动，是因为 OCV 本身已经很高（本例 74% 时 OCV ≈ 4.31V，健康电池同电量约 4.05V），留给电流的电压余量只剩一百多毫伏。**这个区间任何软件方案都无效，只能换电池。**

## 安装

1. 需要已 root（KernelSU 或 Magisk）
2. KernelSU 管理器 → 模块 → 从本地安装 → 选择 `OplusFlashFix.zip`
3. 重启

```sh
# 确认在跑
su -c sh /data/adb/modules/oplus_flash_fix/capctl status
```

## 回落自动恢复（v2.2 新增）

100W 头稳定跑一段后会回落（实测约 45% 电量以上），回落即 `voocchg_ing=0`、电流掉到 0.5A。
v2.2 会检测这个状态并自动强制重新协商，不用手动拔插。

实测三种手段，只有一种有效：

| 手段 | 结果 |
|---|---|
| `otg_switch` 翻转 1→0 | 无效，VBUS 不断，不重协商 |
| `stop_charging_enable` 翻转 | 无效 |
| **`mmi_charging_enable` 0 → 1** | **有效，4 秒内恢复到 8.85V / 1.33A** |

触发条件（全部满足）：

- `voocchg_ing = 0` 且实测电流 < `RECOVER_CUR`（默认 800mA）
- 已插上超过 `RECOVER_GRACE_TICKS`（约 10 秒，避免打断正常协商）
- 电量 < `RECOVER_MAX_PERCENT`（默认 80%，高电量本身跑不动快充）
- 距上次尝试超过 `RECOVER_COOLDOWN_TICKS`（约 25 秒）

关闭：`RECOVER=0`

## 配置

`/data/adb/modules/oplus_flash_fix/config.sh`，改完 4 秒内自动热生效（v2.0 起）。

```sh
# 目标电流上限（mA）
TARGET_BCC_MA=3000

# 温度到 38.0C 砍半，43.0C 完全放手
TEMP_DERATE=380
TEMP_LIMIT=430

# 充到 80% 就停止干预（0 = 关闭）
STOP_AT_PERCENT=0
```

或用命令行：

```sh
su -c sh /data/adb/modules/oplus_flash_fix/capctl set TARGET_BCC_MA 2600
su -c sh /data/adb/modules/oplus_flash_fix/capctl log
su -c sh /data/adb/modules/oplus_flash_fix/capctl off
```

## 怎么找你自己机型的正确值

不同机型、不同老化程度的最佳值不一样。按这个流程测：

```sh
# 1. 插上原装快充头，观察是否会在几秒内断开
su -c "while true; do cat /sys/class/power_supply/battery/current_now \
  /sys/class/power_supply/battery/voltage_now \
  /sys/class/oplus_chg/battery/voocchg_ing; sleep 1; done"

# 2. 如果 voocchg_ing 从 1 变 0 且电流变成正数，就是跳闸了
# 3. 把 TARGET_BCC_MA 往下调 500mA，重新插拔再试
# 4. 找到既能保持 voocchg_ing=1、端电压又不逼近跳闸点的最大值
```

判断跳闸点：观察跳闸瞬间的 `voltage_now`，本例是 4539mV。模块的目标就是让端电压长期停在这个值**以下**。

## 适用范围与限制

✅ 适用：

- OPPO / 一加 / realme 的 oplus_chg 充电框架（存在 `/sys/class/oplus_chg/` 节点）
- 电池老化、内阻升高导致快充跳闸的机型
- 有 root 的机器

❌ 不适用 / 做不到：

- 没有 `/sys/class/oplus_chg/battery/bcc_current` 节点的机型
- 想让老电池回到 100W：做不到。本例 `g_voocphy_chip` 为 null，电荷泵通路不可用，天花板约 18~20W；即便通路正常，也是电池内阻先触顶
- 高电量区间提速：做不到，物理限制

## 免责声明

修改充电参数存在风险，包括但不限于电池鼓包、过热、异常断充。本模块默认值偏保守（3A + 42°C 以上放手），但仍请自行评估。**电池老化到 SoH 30% 以下的，正确做法是换电池，不是调参数。**

## License

MIT
