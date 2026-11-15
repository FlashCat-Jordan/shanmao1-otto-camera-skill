# 闪猫1号 Otto 摄像头版开发 Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

这是一个给 **AI Agent / Coding Agent / 0 基础用户** 使用的开发 Skill，目标是把 **闪猫1号 Otto 摄像头版** 的开发环境、编译、烧录和二次开发路径讲清楚，让 Agent 不再从零猜工程结构。

> 这是一个 Skill 仓库，不是固件发布仓库。固件源码默认使用 ESP-IDF 的 `otto-robot` 板级工程；如果用户有闪猫1号工厂源码，可以使用自己的 `FIRMWARE_DIR`。

## 它能做什么

- 检查并准备 ESP-IDF / Python / 串口环境；
- 处理 macOS 中文路径导致的 `picolibc.specs` 构建失败；
- 编译 `otto-robot` 摄像头版固件；
- 区分“完整烧录”和“只更新 app、保留 Wi-Fi”；
- 指导修改舵机动作、摄像头、表情、音频、MCP 工具；
- 给出摄像头/舵机/麦克风/唤醒词的常见故障排查；
- 明确告诉 Agent 哪些改动必须实机验证。

## 硬件

- ESP32-S3 CAM 板，16MB Flash；
- 六舵机：双腿、双脚、脖子、嘴巴；
- 1.54 英寸 ST7789 240×240 屏幕；
- I2S 麦克风 + 扬声器；
- 可选 OV2640 / OV3660 / GC2145 摄像头；
- 可充电锂电池。

实际引脚以用户板子的 `config.h` 和丝印为准，详见 [references/hardware.md](references/hardware.md)。

## 快速开始

```bash
git clone https://github.com/FlashCat-Jordan/shanmao1-otto-camera-skill.git
cd shanmao1-otto-camera-skill

bash scripts/check-env.sh
bash scripts/build.sh
bash scripts/flash.sh --app-only /dev/cu.usbmodemXXXX
```

首次烧录或需要彻底恢复：

```bash
bash scripts/flash.sh /dev/cu.usbmodemXXXX build/merged-binary.bin
```

> 完整镜像从 `0x0` 写入，会覆盖 NVS / Wi-Fi 配网信息。只想保留配网时用 `--app-only`。

## 交给 AI Agent

把仓库链接发给 Agent，并说：

> 读 `SKILL.md`，先检查我的环境，然后帮我编译并烧录闪猫1号 Otto 摄像头版。

Agent 会按以下顺序工作：

1. 读 `SKILL.md`；
2. 跑 `scripts/check-env.sh`；
3. 缺环境时读 `references/environment.md`；
4. 编译、烧录；
5. 按 `references/recipes.md` 做二次开发；
6. 用 `references/troubleshooting.md` 排查问题。

## 目录

```text
.
├── SKILL.md                    # Agent 主入口
├── README.md
├── LICENSE
├── references/
│   ├── environment.md          # 环境、ESP-IDF、ASCII 路径
│   ├── hardware.md             # 板级、引脚、舵机安全
│   ├── firmware.md             # 工程结构、分区、构建/烧录
│   ├── recipes.md              # 加动作、改摄像头、改表情、改唤醒词
│   └── troubleshooting.md      # 常见故障
├── scripts/
│   ├── check-env.sh
│   ├── setup-env.sh
│   ├── prepare-ascii-build.sh
│   ├── build.sh
│   └── flash.sh
└── examples/
    └── prompts.md              # 可以直接发给 Agent 的例子
```

## 适用范围

- 闪猫1号 / Otto 摄像头版（CAM 板）；
- ESP-IDF 6.0.1+；
- 语音固件 `otto-robot`；
- 二次开发：动作、摄像头、屏幕、音频、MCP、唤醒词。

## 重要说明

- **唤醒词**：预训练模型可以直接切换；自定义“你好闪猫”需要训练新的 WakeNet 模型，不能只改拼音配置。
- **摄像头**：GC2145 可能需要方向修正，具体取决于模组装配方向。
- **配网**：完整烧录会清 NVS；更新 app 时优先保留 NVS。
- **安全**：编译成功不代表硬件验证通过；舵机限位、摄像头方向、音频和电池必须实机确认。

## License

本 Skill 使用 MIT License。固件源码和第三方组件遵循其各自许可证；ESP-SR 预训练模型的使用请遵守 Espressif 的模型许可。
