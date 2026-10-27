# 调查记录

全部数据来自一台 OnePlus Ace（PGKM10，ColorOS 13.1.0.190，MTK MT6895，KernelSU），
电池 SoH 41%，容量保持 57%（2584mAh / 4500mAh）。

## 1. 环境确认

```sh
uname -a
# Linux 5.10.149-android12-9 aarch64

ls /sys/class/oplus_chg/
# ac  battery  common  usb  wireless
```

可写节点（`-rw-` 权限，root 可写）：

| 节点 | 初始值 | 含义 |
|---|---|---|
| `oplus_chg/battery/bcc_current` | 6500 | 电池充电电流上限 |
| `oplus_chg/battery/charge_technology` | 9 | 充电技术标识 |
| `oplus_chg/battery/stop_charging_enable` | 1 | 停充开关 |
| `oplus_chg/usb/fast_chg_type` | 105 | 快充类型（只读镜像，写入无效果） |
| `mtk-master-charger/input_current_limit` | 500000 | 输入限流（被 HAL 每 100ms 内重置，无效） |
| `mtk-master-charger/constant_charge_current_max` | 2000000 | 主充恒流上限（不约束 VOOC 路径） |

只读：`battery_soh`(41)、`fast_charge`、`voocchg_ing`、`soh_report`。

## 2. 被排除的可能

| 假设 | 检验 | 结论 |
|---|---|---|
| 非原装电池被拒绝 | `authenticate=1` | 排除 |
| 进水检测限流 | `water_detect_feature=0` | 排除 |
| 输入限流设太低 | 100ms 高频重写 `input_current_limit`，读回始终 500000，电流不变 | 排除，写入被忽略 |
| 强制快充类型 | 写 `fast_chg_type=1` 读回 1，但 `voocchg_ing` 仍为 0 | 排除，纯状态镜像 |
| 电荷泵可用 | dmesg 持续输出 `g_voocphy_chip or chip is null`，`VOOCPHY[0/0/0/0/0/0x0]` | SUPERVOOC 通路不可用 |

## 3. 100ms 粒度的跳闸过程

```
i,ms,cap,cur,volt,temp,fct,vooc,inlim,ccmax,bcc,otg,status
261,26100,23,-146,3802,278,105,1,500000,2000000,7000,1,Charging
264,26400,23,-2230,3802,280,105,1,500000,2000000,7000,1,Charging
288,28800,24,-4329,3802,283,105,1,500000,2000000,6500,1,Charging
297,29700,24,-4329,4539,275,105,1,100000,2000000,6500,1,Charging
302,30200,24,-260,4539,275,105,0,100000,2000000,6500,1,Charging
304,30400,24,99,4539,275,105,0,100000,2000000,6500,1,Charging
```

`inlim` 掉到 100000 是保护动作，随后 `vooc` 归零、电流变正（反向放电）。

101 秒内重复了 8 次，每次维持 2~7 秒。

## 4. bcc_current 档位实测

### 6500（默认）
纹波极大，冲到 4329mA 后跳闸，平均约 1A。

### 3000 —— 有效
```
t=78s   cap=17%  cur=-187   volt=3815  vbus=8825
t=84s   cap=18%  cur=-2429  volt=4483  vbus=8850
t=150s  cap=22%  cur=-2429  volt=4439  vbus=8900
t=210s  cap=25%  cur=-2431  volt=4454  vbus=8925
```
连续 131 秒无中断，温升 1.5°C。

### 4000 —— 更差
手机改走 11V 档（`vbus=10975mV`），只有 1.8 秒的 2266mA 尖峰，随后回落到 5.2V/0.56A 且不再重试。
整段 187 秒里 612/624 帧都在 0.56A。

### 1500 —— 无法进入 VOOC
停在 5V/0.575A。推测低于 VOOC 最低档位（2A）时不发起协商。

## 5. 高电量区间

| 电量 | 充电头 | 电流 | 端电压 | VBUS |
|---|---|---|---|---|
| 17~30% | 100W | 2.43A | 4469mV | 8.9V |
| 64~66% | 100W | 0.575A | 4339mV | 5.2V |
| 73~74% | 30W | 0.64A | 4417mV | 5.15V |

74% 时反推 OCV ≈ 4308mV（健康电池同电量约 4050mV），端电压距跳闸点只剩 122mV，
可用电流余量仅约 1.3A，低于 VOOC 起跳门限。两个充电头表现一致，说明限制在电池侧而非充电器侧。

## 6. 节点单位的坑

`bcc_current` 的 setter 会把写入值乘 100：

```sh
echo 4000  > bcc_current   # 读回 400000
echo 15    > bcc_current   # 读回 1500
```

所以写 30 才等于 3000mA。模块内部做 `TARGET_BCC_MA / 100` 换算。
